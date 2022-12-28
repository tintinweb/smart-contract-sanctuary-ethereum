// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)
library LibString {
    function toString(uint256 value) internal pure returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but we allocate 160 bytes
            // to keep the free memory pointer word aligned. We'll need 1 word for the length, 1 word for the
            // trailing zeros padding, and 3 other words for a max of 78 digits. In total: 5 * 32 = 160 bytes.
            let newFreeMemoryPointer := add(mload(0x40), 160)

            // Update the free memory pointer to avoid overriding our string.
            mstore(0x40, newFreeMemoryPointer)

            // Assign str to the end of the zone of newly allocated memory.
            str := sub(newFreeMemoryPointer, 32)

            // Clean the last word of memory it may not be overwritten.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                // Move the pointer 1 byte to the left.
                str := sub(str, 1)

                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))

                // Keep dividing temp until zero.
                temp := div(temp, 10)

                 // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute and cache the final total length of the string.
            let length := sub(end, str)

            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 32)

            // Store the string's length at the start of memory allocated for our string.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 _______  _______  _______  _        _        _______  _          _______           _        _        _______
(  ____ \(  ____ )(  ___  )( (    /|| \    /\(  ____ \( (    /|  (  ____ )|\     /|( (    /|| \    /\(  ____ \
| (    \/| (    )|| (   ) ||  \  ( ||  \  / /| (    \/|  \  ( |  | (    )|| )   ( ||  \  ( ||  \  / /| (    \/
| (__    | (____)|| (___) ||   \ | ||  (_/ / | (__    |   \ | |  | (____)|| |   | ||   \ | ||  (_/ / | (_____
|  __)   |     __)|  ___  || (\ \) ||   _ (  |  __)   | (\ \) |  |  _____)| |   | || (\ \) ||   _ (  (_____  )
| (      | (\ (   | (   ) || | \   ||  ( \ \ | (      | | \   |  | (      | |   | || | \   ||  ( \ \       ) |
| )      | ) \ \__| )   ( || )  \  ||  /  \ \| (____/\| )  \  |  | )      | (___) || )  \  ||  /  \ \/\____) |
|/       |/   \__/|/     \||/    )_)|_/    \/(_______/|/    )_)  |/       (_______)|/    )_)|_/    \/\_______)

*/

import "solmate/tokens/ERC721.sol";
import "solmate/utils/LibString.sol";
import "./utils/SafeCast.sol";
import "./utils/Refundable.sol";
import "./utils/Admin.sol";

import "./interfaces/IERC721.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/IExecutor.sol";

/// @title FrankenDAO Staking
/// @author Zach Obront & Zakk Fleischmann
/// @notice Users stake FrankenPunks & FrankenMonsters and get ERC721s in return
/// @notice These ERC721s are used for voting power for FrankenDAO governance
contract Staking is IStaking, ERC721, Admin, Refundable {
  using LibString for uint256;

  /// @notice The original ERC721 FrankenPunks contract
  IERC721 frankenpunks;
  
  /// @notice The original ERC721 FrankenMonsters contract
  IERC721 frankenmonsters;

  /// @notice The DAO governance contract (where voting occurs)
  IGovernance governance;

  /// @notice Base votes for holding a Frankenpunk token
  uint constant public BASE_VOTES = 20;

  /// @return maxStakeBonusTime The maxmimum time you will earn bonus votes for staking for
  /// @return maxStakeBonusAmount The amount of bonus votes you'll get if you stake for the max time
  StakingSettings public stakingSettings;

  /// @notice Multipliers (expressed as percentage) for calculating community voting power from user stats
  /// @return votes The multiplier for extra voting power earned per DAO vote cast
  /// @return proposalsCreated The multiplier for extra voting power earned per proposal created
  /// @return proposalsPassed The multiplier for extra voting power earned per proposal passed
  CommunityPowerMultipliers public communityPowerMultipliers;

  /// @notice Constant to calculate voting power based on multipliers above
  uint constant PERCENT = 100;

  /// @notice Are refunds turned on for staking?
  bool public stakingRefund;

  /// @notice The last timestamp at which a user used their staking refund
  mapping(address => uint256) public lastStakingRefund;

  /// @notice Are refunds turned on for delegating?
  bool public delegatingRefund;

  /// @notice The last timestamp at which a user used their delegating refund
  mapping(address => uint256) public lastDelegatingRefund;

  /// @notice How often can a user use their refund?
  uint256 public refundCooldown;

  /// @notice Is staking currently paused or open?
  bool public paused;

  /// @notice The staked time bonus for each staked token (tokenId => bonus votes)
  /// @dev This needs to be tracked because users will select how much time to lock for, so bonus is variable
  mapping(uint => uint) stakedTimeBonus; 
  
  /// @notice The allowed unlock time for each staked token (tokenId => timestamp)
  /// @dev This remains at 0 if tokens are staked without locking
  mapping(uint => uint) public unlockTime;

  /// @notice Addresses that each user delegates votes to
  /// @dev This should only be accessed via getDelegate() function, which overrides address(0) with self
  mapping(address => address) private _delegates;

  /// @notice The total voting power earned by each user's staked tokens
  /// @dev In other words, this is the amount of voting power that would move if they redelegated
  /// @dev They don't necessarily have this many votes, because they may have delegated them
  mapping(address => uint) public votesFromOwnedTokens;

  /// @notice The total voting power each user has, after adjusting for delegation
  /// @dev This represents the actual token voting power of each user
  mapping(address => uint) public tokenVotingPower;

  /// @notice The total token voting power of the system
  uint totalTokenVotingPower;

  /// @notice Base token URI for the ERC721s representing the staked position
  string public baseTokenURI;

  /// @notice Contract URI for marketplace metadata
  string public contractURI;

  /// @notice The total supply of staked frankenpunks
  uint128 public stakedFrankenPunks;

  /// @notice The total supply of staked frankenmonsters
  uint128 public stakedFrankenMonsters;

  /// @notice Bitmaps representing whether each FrankenPunk has a sufficient "evil score" for a bonus.
  /// @dev 40 words * 256 bits = 10,240 bits, which is sufficient to hold values for 10k FrankenPunks
  uint[40] EVIL_BITMAPS = [
    883425322698150530263834307704826599123904599330160270537777278655401984, // 0
    14488147225470816109160058996749687396265978336526515174837584423109802852352, // 1
    38566513062215815139428642218823858442255833421860837338906624, // 2
    105312291668557186697918027683670432324476705909712387428719788032, // 3
    14474011154664524427946373126085988481660077311200856629730921422678596263936, // 4
    3618502788692465607655909614339766499850336868450542774889103259212619972609, // 5
    441711772776714745308416192199486840791445460561420424832198410539892736, // 6
    6901746759773641161995257390185172072446268286034776944761674561224712, // 7
    883423532414903565819785182543377466397133986207912949084155019599544320, // 8
    14474011155086185177904289442148664541270784730116237084843513087002589265920, // 9
    107839786668798718607898896909541540930351713584408019687362806153216, // 10
    904625700641838402593673198335004289144275540958779302917589231213362556944, // 11
    220859253090631447287862539909960206022391538433640386622889848771706880, // 12
    1393839110204029063653915313866451565150208, // 13
    784637716923340670665773318162647287385528792673206407169, // 14
    107839786668602559178668060353525740564723109496935832847049186869248, // 15
    51422802054004612152481822571560984362335820545231474237898784, // 16
    6582018229284824169333500576582381960460086447259084614308728832, // 17
    365732221255902219560809532335122355265736818688, // 18
    445162639419413381705829464770174011933371831432841644599383048677490688, // 19
    6935446280124502090171244984389489167294584349705235353545399909482504, // 20
    452312848583266388373372050675839373643513806386188657447441353755011973120, // 21
    51422023594160337932957247212003666383914706547133656225284128, // 22
    2923003274661805998666646494941077336069228208128, // 23
    215679573337205118357336126271343355406346657833909405071980653182976, // 24
    26959946667150639794667015087041235820865508444839585222888876146720, // 25
    3731581108651760187459529718884681603688140590625042088037390915407571845120, // 26
    33372889303170710042455474178259135664197736114694375141005066752, // 27
    28948022309329151699928351061631107912622119818910282538292189430411643863044, // 28
    55214023430470347690952963241066788995217469738067023806554216123598848, // 29
    55213971185700649632772712790212230970723509677757939395778641765335297, // 30
    50216813883139118038214077107913983031541181002059654103040, // 31
    45671926166601100787582220677640905906662146176, // 32
    431359146674410260659915067596052074490887103277477952745659311325184, // 33
    6741683593362397442763285474207733540211166501858783908538903166976, // 34
    421249166674235107246797774824181756792478284093098635821743865856, // 35
    53919893334350319447007114026840783409769671338355940037889148190720, // 36
    401740641047276407850947922339698016834483256774579142524928, // 37
    220855883097304318299647574273628650268020954052697685772267193358090240, // 38
    0 // 39
  ];

  /////////////////////////////////
  /////////// MODIFIERS ///////////
  /////////////////////////////////

  /// @dev To avoid needing to checkpoint voting power, tokens are locked while users have active votes cast or proposals open
  /// @dev If a user creates a proposal or casts a vote, this modifier prevents them from unstaking or delegating
  /// @dev Once the proposal is completed, it is removed from getActiveProposals and their tokens are unlocked
  modifier lockedWhileVotesCast() {
    uint[] memory activeProposals = governance.getActiveProposals();
    for (uint i = 0; i < activeProposals.length; i++) {
      if (governance.getReceipt(activeProposals[i], getDelegate(msg.sender)).hasVoted) revert TokenLocked();
      (, address proposer,) = governance.getProposalData(activeProposals[i]);
      if (proposer == getDelegate(msg.sender)) revert TokenLocked();
    }
    _;
  }

  /////////////////////////////////
  ////////// CONSTRUCTOR //////////
  /////////////////////////////////

  /// @param _frankenpunks The address of the original ERC721 FrankenPunks contract
  /// @param _frankenmonsters The address of the original ERC721 FrankenMonsters contract
  /// @param _governance The address of the DAO governance contract
  /// @param _executor The address of the DAO executor contract
  /// @param _founders The address of the founder multisig for restricted functions
  /// @param _council The address of the council multisig for restricted functions
  /// @param _baseTokenURI Token URI for the Staking NFT contract
  /// @param _contractURI URI for the contract metadata
  constructor(
    address _frankenpunks, 
    address _frankenmonsters,
    address _governance, 
    address _executor, 
    address _founders,
    address _council,
    string memory _baseTokenURI,
    string memory _contractURI
  ) ERC721("Staked FrankenPunks", "sFP") {
    frankenpunks = IERC721(_frankenpunks);
    frankenmonsters = IERC721(_frankenmonsters);
    governance = IGovernance( _governance );

    executor = IExecutor(_executor);
    founders = _founders;
    council = _council;

    // Staking bonus increases linearly from 0 to 20 votes over 4 weeks
    stakingSettings = StakingSettings({
      maxStakeBonusTime: uint128(4 weeks), 
      maxStakeBonusAmount: uint128(20)
    });

    // Users get a bonus 1 vote per vote, 2 votes per proposal created, and 2 votes per proposal passed
    communityPowerMultipliers = CommunityPowerMultipliers({
      votes: uint64(100), 
      proposalsCreated: uint64(200),
      proposalsPassed: uint64(200)
    });

    // Refunds are initially turned on with 1 day cooldown.
    delegatingRefund = true;
    stakingRefund = true;
    refundCooldown = 1 days;

    // Set the base token URI.
    baseTokenURI = _baseTokenURI;

    // Set the contract URI.
    contractURI = _contractURI;
  }

  /////////////////////////////////
  // OVERRIDE & REVERT TRANSFERS //
  /////////////////////////////////  

  /// @notice Transferring of staked tokens is prohibited, so all transfers will revert
  /// @dev This will also block safeTransferFrom, because of solmate's implementation
  function transferFrom(address, address, uint256) public pure override(ERC721) {
    revert StakedTokensCannotBeTransferred();
  }

  /////////////////////////////////
  /////// TOKEN URI FUNCTIONS /////
  /////////////////////////////////

  /// @notice Token URI to find metadata for each tokenId
  /// @dev The metadata will be a variation on the metadata of the underlying token
  function tokenURI(uint256 _tokenId) public view virtual override(ERC721) returns (string memory) {
    if (ownerOf(_tokenId) == address(0)) revert NonExistentToken();

    string memory baseURI = baseTokenURI;
    return bytes(baseURI).length > 0
      ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"))
      : "";
  }

  /////////////////////////////////
  /////// DELEGATION LOGIC ////////
  /////////////////////////////////

  /// @notice Return the address that a given address delegates to
  /// @param _delegator The address to check 
  /// @return The address that the delegator has delegated to
  /// @dev If the delegator has not delegated, this function will return their own address
  function getDelegate(address _delegator) public view returns (address) {
    address current = _delegates[_delegator];
    return current == address(0) ? _delegator : current;
  }

  /// @notice Delegate votes to another address
  /// @param _delegatee The address you wish to delegate to
  /// @dev Refunds gas if delegatingRefund is true and hasn't been used by this user in the past 24 hours
  function delegate(address _delegatee) public {
    if (_delegatee == address(0)) _delegatee = msg.sender;
    
    // Refunds gas if delegatingRefund is true and hasn't been used by this user in the past 24 hours
    if (delegatingRefund && lastDelegatingRefund[msg.sender] + refundCooldown <= block.timestamp) {
      uint256 startGas = gasleft();
      _delegate(msg.sender, _delegatee);
      lastDelegatingRefund[msg.sender] = block.timestamp;
      _refundGas(startGas);
    } else {
      _delegate(msg.sender, _delegatee);
    }
  }

  /// @notice Delegates votes from the sender to the delegatee
  /// @param _delegator The address of the user who called the function and owns the votes being delegated
  /// @param _delegatee The address of the user who will receive the votes
  function _delegate(address _delegator, address _delegatee) internal lockedWhileVotesCast {
    address currentDelegate = getDelegate(_delegator);
    // If currentDelegate == _delegatee, then this function will not do anything
    if (currentDelegate == _delegatee) revert InvalidDelegation();

    // Set the _delegates mapping to the correct address, subbing in address(0) if they are delegating to themselves
    _delegates[_delegator] = _delegatee == _delegator ? address(0) : _delegatee;
    uint amount = votesFromOwnedTokens[_delegator];

    // If the delegator has no votes, then this function will not do anything
    // This is explicitly blocked to ensure that users without votes cannot abuse the refund mechanism
    if (amount == 0) revert InvalidDelegation();
    
    // Move the votes from the currentDelegate to the new delegatee
    // Neither of these addresses can be address(0) because: 
    // - currentDelegate calls getDelegate(), which replaces address(0) with the delegator's address
    // - delegatee is changed to msg.sender in the external functions if address(0) is passed
    tokenVotingPower[currentDelegate] -= amount;
    tokenVotingPower[_delegatee] += amount; 

    // If this moved the current delegate down to zero voting power, then remove their community VP from the totals
    if (tokenVotingPower[currentDelegate] == 0) {
        _updateTotalCommunityVotingPower(currentDelegate, false);
    }

    // If the new delegate previously had zero voting power, then add their community VP to the totals
    if (tokenVotingPower[_delegatee] == amount) {
      _updateTotalCommunityVotingPower(_delegatee, true);
    }

    emit DelegateChanged(_delegator, currentDelegate, _delegatee);
  }

  /// @notice Updates the total community voting power totals
  /// @param _delegator The address of the user who called the function and owns the votes being delegated
  /// @param _increase Should we be increasing or decreasing the totals?
  /// @dev This function is called by _delegate, _stake, and _unstake
  function _updateTotalCommunityVotingPower(address _delegator, bool _increase) internal {
    (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed) = governance.userCommunityScoreData(_delegator);
    (uint64 totalVotes, uint64 totalProposalsCreated, uint64 totalProposalsPassed) = governance.totalCommunityScoreData();

    if (_increase) {
      governance.updateTotalCommunityScoreData(totalVotes + votes, totalProposalsCreated + proposalsCreated, totalProposalsPassed + proposalsPassed);
    } else {
      governance.updateTotalCommunityScoreData(totalVotes - votes, totalProposalsCreated - proposalsCreated, totalProposalsPassed - proposalsPassed);
    }
  }

  /////////////////////////////////
  /// STAKE & UNSTAKE FUNCTIONS ///
  /////////////////////////////////

  /// @notice Stake your tokens to get voting power
  /// @param _tokenIds An array of the id of the token you wish to stake
  /// @param _unlockTime The timestamp of the time your tokens will be unlocked
  /// @dev unlockTime can be set to 0 to stake without locking (and earn no extra staked time bonus)
  function stake(uint[] calldata _tokenIds, uint _unlockTime) public {
    // Refunds gas if stakingRefund is true and hasn't been used by this user in the past 24 hours
    if (stakingRefund && lastStakingRefund[msg.sender] + refundCooldown <= block.timestamp) {
      uint256 startGas = gasleft();
      _stake(_tokenIds, _unlockTime);
      lastStakingRefund[msg.sender] = block.timestamp;
      _refundGas(startGas);
    } else {
      _stake(_tokenIds, _unlockTime);
    }
  }

  /// @notice Internal function to stake tokens and get voting power
  /// @param _tokenIds An array of the id of the tokens being staked
  /// @param _unlockTime The timestamp of when the tokens will be unlocked
  function _stake(uint[] calldata _tokenIds, uint _unlockTime) internal {
    if (paused) revert Paused();
    if (_unlockTime > 0 && _unlockTime < block.timestamp) revert InvalidParameter();

    uint maxStakeTime = stakingSettings.maxStakeBonusTime;
    if (_unlockTime > 0 && _unlockTime - block.timestamp > maxStakeTime) {
      _unlockTime = block.timestamp + maxStakeTime;
    }

    uint numTokens = _tokenIds.length;
    // This is required to ensure the gas refunds are not abused
    if (numTokens == 0) revert InvalidParameter();
    
    uint newVotingPower;
    for (uint i = 0; i < numTokens; i++) {
        newVotingPower += _stakeToken(_tokenIds[i], _unlockTime);
    }

    votesFromOwnedTokens[msg.sender] += newVotingPower;
    tokenVotingPower[getDelegate(msg.sender)] += newVotingPower;
    totalTokenVotingPower += newVotingPower;

    // If the delegate (including self) had no tokenVotingPower before, they just unlocked their community voting power
    if (tokenVotingPower[getDelegate(msg.sender)] == newVotingPower) {
      // The delegate's community voting power is reactivated, so we add it to the total community voting power
      _updateTotalCommunityVotingPower(getDelegate(msg.sender), true);
    }
  }

  /// @notice Internal function to stake a single token and get voting power
  /// @param _tokenId The id of the token being staked
  /// @param _unlockTime The timestamp of when the token will be unlocked
  function _stakeToken(uint _tokenId, uint _unlockTime) internal returns (uint) {
    if (_unlockTime > 0) {
      unlockTime[_tokenId] = _unlockTime;
      uint fullStakedTimeBonus = ((_unlockTime - block.timestamp) * stakingSettings.maxStakeBonusAmount) / stakingSettings.maxStakeBonusTime;
      stakedTimeBonus[_tokenId] = _tokenId < 10000 ? fullStakedTimeBonus : fullStakedTimeBonus / 2;
    }

    // Transfer the underlying token from the owner to this contract
    IERC721 collection;
    if (_tokenId < 10000) {
      collection = frankenpunks;
      stakedFrankenPunks++;
    } else {
      collection = frankenmonsters;
      stakedFrankenMonsters++;
    }

    address owner = collection.ownerOf(_tokenId);
    if (msg.sender != owner) revert NotAuthorized();
    collection.transferFrom(owner, address(this), _tokenId);

    // Mint the staker a new ERC721 token representing their staked token
    _mint(msg.sender, _tokenId);

    // Return the voting power for this token based on staked time bonus and evil score
    return getTokenVotingPower(_tokenId);
  }

  /// @notice Unstake your tokens and surrender voting power
  /// @param _tokenIds An array of the ids of the tokens you wish to unstake
  /// @param _to The address to send the underlying NFT to
  function unstake(uint[] calldata _tokenIds, address _to) public {
    _unstake(_tokenIds, _to);
  }

  /// @notice Internal function to unstake tokens and surrender voting power
  /// @param _tokenIds An array of the ids of the tokens being unstaked
  /// @param _to The address to send the underlying NFT to
  function _unstake(uint[] calldata _tokenIds, address _to) internal lockedWhileVotesCast {
    uint numTokens = _tokenIds.length;
    if (numTokens == 0) revert InvalidParameter();
    
    uint lostVotingPower;
    for (uint i = 0; i < numTokens; i++) {
        lostVotingPower += _unstakeToken(_tokenIds[i], _to);
    }

    votesFromOwnedTokens[msg.sender] -= lostVotingPower;
    // Since the delegate currently has the voting power, it must be removed from their balance
    // If the user doesn't delegate, delegates(msg.sender) will return self
    tokenVotingPower[getDelegate(msg.sender)] -= lostVotingPower;
    totalTokenVotingPower -= lostVotingPower;

    // If this unstaking reduced the user or their delegate's tokenVotingPower to 0, then someone just lost their community voting power
    // First, check if the user is their own delegate
    if (msg.sender == getDelegate(msg.sender)) {
      // Did their tokenVotingPower just become 0?
      if (tokenVotingPower[msg.sender] == 0) {
        // If so, reduce the total voting power to capture this decrease in the user's community voting power
        _updateTotalCommunityVotingPower(msg.sender, false);
      }
    // If they aren't their own delegate...
    } else {
      // If their delegate's tokenVotingPower reaches 0, that means they were the final unstake and the delegate loses community voting power
      if (tokenVotingPower[getDelegate(msg.sender)] == 0) {
        // The delegate's community voting power is forfeited, so we adjust total community power balances down
        _updateTotalCommunityVotingPower(getDelegate(msg.sender), false);
      }
    }
  }

  /// @notice Internal function to unstake a single token and surrender voting power
  /// @param _tokenId The id of the token being unstaked
  /// @param _to The address to send the underlying NFT to
  function _unstakeToken(uint _tokenId, address _to) internal returns(uint) {
    address owner = ownerOf(_tokenId);
    if (msg.sender != owner) revert NotAuthorized();
    if (unlockTime[_tokenId] > block.timestamp) revert TokenLocked();
    
    // Transfer the underlying token from the owner to this contract
    IERC721 collection;
    if (_tokenId < 10000) {
      collection = frankenpunks;
      --stakedFrankenPunks;
    } else {
      collection = frankenmonsters;
      --stakedFrankenMonsters;
    }
    collection.safeTransferFrom(address(this), _to, _tokenId);

    // Voting power needs to be calculated before staked time bonus is zero'd out, as it uses this value
    uint lostVotingPower = getTokenVotingPower(_tokenId);
    _burn(_tokenId);

    if (unlockTime[_tokenId] > 0) {
      delete unlockTime[_tokenId];
      delete stakedTimeBonus[_tokenId];
    }

    return lostVotingPower;
  }

    //////////////////////////////////////////////
    ///// VOTING POWER CALCULATION FUNCTIONS /////
    //////////////////////////////////////////////
    
    /// @notice Get the total voting power (token + community) for an account
    /// @param _account The address of the account to get voting power for
    /// @return The total voting power for the account
    /// @dev This is used by governance to calculate the voting power of an account
    function getVotes(address _account) public view returns (uint) {
        return tokenVotingPower[_account] + getCommunityVotingPower(_account);
    }
    
    /// @notice Get the voting power for a specific token when staking or unstaking
    /// @param _tokenId The id of the token to get voting power for
    /// @return The voting power for the token
    /// @dev Voting power is calculated as baseVotes + staking bonus (0 to max staking bonus) + evil bonus (0 or 10)
    function getTokenVotingPower(uint _tokenId) public override view returns (uint) {
      if (ownerOf(_tokenId) == address(0)) revert NonExistentToken();

      // If tokenId < 10000, it's a FrankenPunk, so BASE_VOTES, otherwise, divide by 2 for monsters
      uint baseVotes = _tokenId < 10_000 ? BASE_VOTES : BASE_VOTES / 2;
      
      // evilBonus will return 0 for all FrankenMonsters, as they are not eligible for the evil bonus
      return baseVotes + stakedTimeBonus[_tokenId] + evilBonus(_tokenId);
    }

    /// @notice Get the community voting power for a given user
    /// @param _voter The address of the account to get community voting power for
    /// @return The community voting power the user currently has
    function getCommunityVotingPower(address _voter) public override view returns (uint) {
      uint64 votes;
      uint64 proposalsCreated;
      uint64 proposalsPassed;
      
      // We allow this function to be called with the max uint value to get the total community voting power
      if (_voter == address(type(uint160).max)) {
        (votes, proposalsCreated, proposalsPassed) = governance.totalCommunityScoreData();
      } else {
        // This is only the case if they are delegated or unstaked, both of which should zero out the result
        if (tokenVotingPower[_voter] == 0) return 0;

        (votes, proposalsCreated, proposalsPassed) = governance.userCommunityScoreData(_voter);
      }

      CommunityPowerMultipliers memory cpMultipliers = communityPowerMultipliers;

      return (
          (votes * cpMultipliers.votes) + 
          (proposalsCreated * cpMultipliers.proposalsCreated) + 
          (proposalsPassed * cpMultipliers.proposalsPassed)
        ) / PERCENT;
    }

    /// @notice Get the total voting power of the entire system
    /// @return The total votes in the system
    /// @dev This is used to calculate the quorum and proposal thresholds
    function getTotalVotingPower() public view returns (uint) {
      return totalTokenVotingPower + getCommunityVotingPower(address(type(uint160).max));
    }

    function getStakedTokenSupplies() public view returns (uint128, uint128) {
      return (stakedFrankenPunks, stakedFrankenMonsters);
    }

    /// @notice Get the evil bonus for a given token
    /// @param _tokenId The id of the token to get the evil bonus for
    /// @return The evil bonus for the token
    /// @dev The evil bonus is 10 if the token is sufficiently evil, 0 otherwise
    function evilBonus(uint _tokenId) public view returns (uint) {
      if (_tokenId >= 10000) return 0; 
      return (EVIL_BITMAPS[_tokenId >> 8] >> (255 - (_tokenId & 255)) & 1) * 10;
    }

  /////////////////////////////////
  //////// OWNER OPERATIONS ///////
  /////////////////////////////////

  /// @notice Set the max staking time needed to get the max bonus
  /// @param _newMaxStakeBonusTime The new max staking time
  /// @dev This function can only be called by the executor based on a governance proposal
  function changeStakeTime(uint128 _newMaxStakeBonusTime) external onlyExecutor {
    if (_newMaxStakeBonusTime == 0) revert InvalidParameter();
    emit StakeTimeChanged(stakingSettings.maxStakeBonusTime = _newMaxStakeBonusTime);
  }

  /// @notice Set the max staking bonus earned if a token is staked for the max time
  /// @param _newMaxStakeBonusAmount The new max staking bonus
  /// @dev This function can only be called by the executor based on a governance proposal
  function changeStakeAmount(uint128 _newMaxStakeBonusAmount) external onlyExecutor {
    emit StakeAmountChanged(stakingSettings.maxStakeBonusAmount = _newMaxStakeBonusAmount);
  }

  /// @notice Set the community power multiplier for votes
  /// @param _votesMultiplier The multiplier applied to community voting power based on past votes
  /// @dev This function can only be called by the executor based on a governance proposal
  function setVotesMultiplier(uint64 _votesMultiplier) external onlyExecutor {
    emit VotesMultiplierChanged(communityPowerMultipliers.votes = _votesMultiplier);
  }

  /// @notice Set the community power multiplier for proposals created
  /// @param _proposalsCreatedMultiplier The multiplier applied to community voting power based on proposals created
  /// @dev This function can only be called by the executor based on a governance proposal
  function setProposalsCreatedMultiplier(uint64 _proposalsCreatedMultiplier) external onlyExecutor {
    emit ProposalsCreatedMultiplierChanged(communityPowerMultipliers.proposalsCreated = _proposalsCreatedMultiplier);
  }

  /// @notice Set the community power multiplier for proposals passed
  /// @param _proposalsPassedMultiplier The multiplier applied to community voting power based on proposals passed
  /// @dev This function can only be called by the executor based on a governance proposal
  function setProposalsPassedMultiplier(uint64 _proposalsPassedMultiplier) external onlyExecutor {
    emit ProposalPassedMultiplierChanged(communityPowerMultipliers.proposalsPassed =  _proposalsPassedMultiplier);
  }

  /// @notice Turn on or off gas refunds for staking and delegating
  /// @param _stakingRefund Should refunds for staking be on (true) or off (false)?
  /// @param _delegatingRefund Should refunds for delegating be on (true) or off (false)?
  /// @param _newCooldown The amount of time a user must wait between refunds of the same type
  function setRefunds(bool _stakingRefund, bool _delegatingRefund, uint _newCooldown) external onlyExecutor {
    emit RefundSettingsChanged(
      stakingRefund = _stakingRefund, 
      delegatingRefund = _delegatingRefund,
      refundCooldown = _newCooldown
    );
  }

  /// @notice Pause or unpause staking
  /// @param _paused Whether staking should be paused or not
  /// @dev This will be used to open and close staking windows to incentivize participation
  function setPause(bool _paused) external onlyPauserOrAdmins {
    emit StakingPause(paused = _paused);
  }

  /// @notice Set hte base URI for the metadata for the staked token
  /// @param _baseURI The new base URI
  function setBaseURI(string calldata _baseURI) external onlyAdmins {
    emit BaseURIChanged(baseTokenURI = _baseURI);
  }

  /// @notice Set the contract URI for marketplace metadata
  /// @param _newContractURI The new contract URI
  function setContractURI(string calldata _newContractURI) external onlyAdmins {
    emit ContractURIChanged(contractURI = _newContractURI);
  }

  /// @notice Check to confirm that this is a FrankenPunks staking contract
  /// @dev Used by governance when upgrading staking to ensure the correct contract
  /// @dev Used instead of an interface because interface may change
  function isFrankenPunksStakingContract() external pure returns (bool) {
    return true;
  }

  /// @notice Contract can receive ETH (will be used to pay for gas refunds)
  receive() external payable {}

  /// @notice Contract can receive ETH (will be used to pay for gas refunds)
  fallback() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract FrankenDAOErrors {
    // General purpose
    error NotAuthorized();

    // Staking
    error NonExistentToken();
    error InvalidDelegation();
    error Paused();
    error InvalidParameter();
    error TokenLocked();
    error StakedTokensCannotBeTransferred();

    // Governance
    error ZeroAddress();
    error AlreadyInitialized();
    error ParameterOutOfBounds();
    error InvalidId();
    error InvalidProposal();
    error InvalidStatus();
    error InvalidInput();
    error AlreadyVoted();
    error NotEligible();
    error NotInActiveProposals();
    error NotStakingContract();

    // Executor
    error DelayNotSatisfied();
    error IdenticalTransactionAlreadyQueued();
    error TransactionNotQueued();
    error TimelockNotMet();
    error TransactionReverted();
}

pragma solidity ^0.8.10;

import {IExecutor} from "./IExecutor.sol";

interface IAdmin {

    ////////////////////
    ////// Events //////
    ////////////////////

    /// @notice Emited when a new address is set for the Council
    event NewCouncil(address oldCouncil, address newCouncil);
    /// @notice Emited when a new address is set for the Founders
    event NewFounders(address oldFounders, address newFounders);
    /// @notice Emited when a new address is set for the Pauser
    event NewPauser(address oldPauser, address newPauser);
    /// @notice Emited when a new address is set for the Verifier
    event NewVerifier(address oldVerifier, address newVerifier);
    /// @notice Emitted when pendingFounders is changed
    event NewPendingFounders(address oldPendingFounders, address newPendingFounders);

    /////////////////////
    ////// Methods //////
    /////////////////////

    function acceptFounders() external;
    function council() external view returns (address);
    function executor() external view returns (IExecutor);
    function founders() external view returns (address);
    function pauser() external view returns (address);
    function pendingFounders() external view returns (address);
    function revokeFounders() external;
    function setCouncil(address _newCouncil) external;
    function setPauser(address _newPauser) external;
    function setPendingFounders(address _newPendingFounders) external;
}

pragma solidity ^0.8.13;

interface IERC721 {
    function approve(address spender, uint id) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function getApproved(uint256 tokenId) external view returns (address);
}

pragma solidity ^0.8.10;

interface IExecutor {

    ////////////////////
    ////// Events //////
    ////////////////////

    /// @notice Emited when a transaction is cancelled
    event CancelTransaction(bytes32 indexed txHash, uint256 id, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    /// @notice Emited when a transaction is executed
    event ExecuteTransaction(bytes32 indexed txHash, uint256 id, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    /// @notice Emited when a new delay value is set
    event NewDelay(uint256 indexed newDelay);
    /// @notice Emited when a transaction is queued
    event QueueTransaction(bytes32 indexed txHash, uint256 id, address indexed target, uint256 value, string signature, bytes data, uint256 eta);

    /////////////////////
    ////// Methods //////
    /////////////////////

    function DELAY() external view returns (uint256);

    function GRACE_PERIOD() external view returns (uint256);

    function cancelTransaction(uint256 _id, address _target, uint256 _value, string memory _signature, bytes memory _data, uint256 _eta) external;

    function executeTransaction(uint256 _id, address _target, uint256 _value, string memory _signature, bytes memory _data, uint256 _eta) external returns (bytes memory);

    function queueTransaction(uint256 _id, address _target, uint256 _value, string memory _signature, bytes memory _data, uint256 _eta) external returns (bytes32 txHash);

    function queuedTransactions(bytes32) external view returns (bool);
}

pragma solidity ^0.8.10;

import {IStaking} from "./IStaking.sol";

interface IGovernance {

    ////////////////////
    ////// Events //////
    ////////////////////

    /// @notice Emited when a proposal is canceled
    event ProposalCanceled(uint256 id);
    /// @notice Emited when a proposal is created
    event ProposalCreated( uint256 id, address proposer, address[] targets, uint256[] values, string[] signatures, bytes[] calldatas, uint32 startTime, uint32 endTime, uint24 quorumVotes, string description);
    /// @notice Emited when a proposal is executed
    event ProposalExecuted(uint256 id);
    /// @notice Emited when a proposal is queued
    event ProposalQueued(uint256 id, uint256 eta);
    /// @notice Emited when a proposal is vetoed
    event ProposalVetoed(uint256 id);
    /// @notice Emited when a new proposal threshold BPS is set
    event ProposalThresholdBPSSet(uint256 oldProposalThresholdBPS, uint256 newProposalThresholdBPS);
    /// @notice Emited when a new quorum votes BPS is set
    event QuorumVotesBPSSet(uint256 oldQuorumVotesBPS, uint256 newQuorumVotesBPS);
    /// @notice Emited when the refund status changes
    event RefundSet(bool isProposingRefund, bool oldStatus, bool newStatus);
    /// @notice Emited when the total community score data is updated
    event TotalCommunityScoreDataUpdated(uint64 proposalsCreated, uint64 proposalsPassed, uint64 votes);
    /// @notice Emited when a vote is cast
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 votes);
    /// @notice Emited when the voting delay is updated
    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);
    /// @notice Emited when the voting period is updated
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);
    /// @notice Emited when the staking contract is changed.
    event NewStakingContract(address stakingContract);

    /////////////////////
    ////// Storage //////
    /////////////////////

    struct CommunityScoreData {
        uint64 votes;
        uint64 proposalsCreated;
        uint64 proposalsPassed;
    }

    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint96 id;
        /// @notice Creator of the proposal
        address proposer;
        /// @notice the ordered list of target addresses for calls to be made
        address[] targets;
        /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint256[] values;
        /// @notice The ordered list of function signatures to be called
        string[] signatures;
        /// @notice The ordered list of calldata to be passed to each call
        bytes[] calldatas;
        /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed at the time of proposal creation. 
        uint24 quorumVotes;
        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint32 eta;
        /// @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint32 startTime;
        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint32 endTime;
        /// @notice Current number of votes in favor of this proposal
        uint24 forVotes;
        /// @notice Current number of votes in opposition to this proposal
        uint24 againstVotes;
        /// @notice Current number of votes for abstaining for this proposal
        uint24 abstainVotes;
        /// @notice Flag marking whether a proposal has been verified
        bool verified;
        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;
        /// @notice Flag marking whether the proposal has been vetoed
        bool vetoed;
        /// @notice Flag marking whether the proposal has been executed
        bool executed;
        /// @notice Receipts of ballots for the entire set of voters
        mapping(address => Receipt) receipts;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;
        /// @notice Whether or not the voter supports the proposal or abstains
        uint8 support;
        /// @notice The number of votes the voter had, which were cast
        uint24 votes;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed,
        Vetoed
    }

    /////////////////////
    ////// Methods //////
    /////////////////////

    function MAX_PROPOSAL_THRESHOLD_BPS() external view returns (uint256);
    function MAX_QUORUM_VOTES_BPS() external view returns (uint256);
    function MAX_VOTING_DELAY() external view returns (uint256);
    function MAX_VOTING_PERIOD() external view returns (uint256);
    function MIN_PROPOSAL_THRESHOLD_BPS() external view returns (uint256);
    function MIN_QUORUM_VOTES_BPS() external view returns (uint256);
    function MIN_VOTING_DELAY() external view returns (uint256);
    function MIN_VOTING_PERIOD() external view returns (uint256);
    function PROPOSAL_MAX_OPERATIONS() external view returns (uint256);
    function activeProposals(uint256) external view returns (uint256);
    function cancel(uint256 _proposalId) external;
    function castVote(uint256 _proposalId, uint8 _support) external;
    function clear(uint256 _proposalId) external;
    function execute(uint256 _proposalId) external;
    function getActions(uint256 _proposalId)
        external
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        );
    function getActiveProposals() external view returns (uint256[] memory);
    function getProposalData(uint256 _proposalId) external view returns (uint256, address, uint256);
    function getProposalStatus(uint256 _proposalId) external view returns (bool, bool, bool, bool);
    function getProposalVotes(uint256 _proposalId) external view returns (uint256, uint256, uint256);
    function getReceipt(uint256 _proposalId, address _voter) external view returns (Receipt memory);
    function initialize(
        address _staking,
        address _executor,
        address _founders,
        address _council,
        uint256 _votingPeriod,
        uint256 _votingDelay,
        uint256 _proposalThresholdBPS,
        uint256 _quorumVotesBPS
    ) external;
    function latestProposalIds(address) external view returns (uint256);
    function name() external view returns (string memory);
    function proposalCount() external view returns (uint256);
    function proposalRefund() external view returns (bool);
    function proposalThreshold() external view returns (uint256);
    function proposalThresholdBPS() external view returns (uint256);
    function proposals(uint256)
        external
        view
        returns (
            uint96 id,
            address proposer,
            uint24 quorumVotes,
            uint32 eta,
            uint32 startTime,
            uint32 endTime,
            uint24 forVotes,
            uint24 againstVotes,
            uint24 abstainVotes,
            bool verified,
            bool canceled,
            bool vetoed,
            bool executed
        );
    function propose(
        address[] memory _targets,
        uint256[] memory _values,
        string[] memory _signatures,
        bytes[] memory _calldatas,
        string memory _description
    ) external returns (uint256);
    function queue(uint256 _proposalId) external;
    function quorumVotes() external view returns (uint256);
    function quorumVotesBPS() external view returns (uint256);
    function setProposalThresholdBPS(uint256 _newProposalThresholdBPS) external;
    function setQuorumVotesBPS(uint256 _newQuorumVotesBPS) external;
    function setRefunds(bool _votingRefund, bool _proposalRefund) external;
    function setStakingAddress(IStaking _newStaking) external;
    function setVotingDelay(uint256 _newVotingDelay) external;
    function setVotingPeriod(uint256 _newVotingPeriod) external;
    function staking() external view returns (IStaking);
    function state(uint256 _proposalId) external view returns (ProposalState);
    function totalCommunityScoreData()
        external
        view
        returns (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed);
    function updateTotalCommunityScoreData(uint64 _votes, uint64 _proposalsCreated, uint64 _proposalsPassed) external;
    function userCommunityScoreData(address)
        external
        view
        returns (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed);
    function verifyProposal(uint256 _proposalId) external;
    function veto(uint256 _proposalId) external;
    function votingDelay() external view returns (uint256);
    function votingPeriod() external view returns (uint256);
    function votingRefund() external view returns (bool);
}

pragma solidity ^0.8.10;

interface IRefundable {

    ////////////////////
    ////// Events //////
    ////////////////////

    /// @notice Emitted when a refund is issued
    event IssueRefund(address refunded, uint256 amount, bool sent, uint256 remainingBalance);

    /// @notice Emited when we're not able to refund the full amount
    event InsufficientFundsForRefund(address refunded, uint256 intendedAmount, uint256 sentAmount);

    /////////////////////
    ////// Methods //////
    /////////////////////

    function MAX_REFUND_PRIORITY_FEE() external view returns (uint256);
    function REFUND_BASE_GAS() external view returns (uint256);
}

pragma solidity ^0.8.10;

interface IStaking {

    ////////////////////
    ////// Events //////
    ////////////////////

    /// @notice Emited a staker changes who they're delegating to
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    /// @notice Emited when staking is paused/unpaused
    event StakingPause(bool status);
    /// @notice Emited when admins change the token's base URI
    event BaseURIChanged(string _baseURI);
    /// @notice Emited when the contract URI is updated
    event ContractURIChanged(string _contractURI);
    /// @notice Emited when refund settings are updated
    event RefundSettingsChanged(bool _stakingRefund, bool _delegatingRefund, uint256 _newCooldown);
    /// @notice Emited when FrankenMonster voting multiplier is changed
    event MonsterMultiplierChanged(uint256 _monsterMultiplier);
    /// @notice Emited when the voting multiplier for passed proposals is changed
    event ProposalPassedMultiplierChanged(uint64 _proposalPassedMultiplier);
    /// @notice Emited when the stake time multiplier is changed
    event StakeTimeChanged(uint128 _stakeTime);
    /// @notice Emited when the staking multiplier is changed
    event StakeAmountChanged(uint128 _stakeAmount);
    /// @notice Emited when the voting multiplier for voting is changed
    event VotesMultiplierChanged(uint64 _votesMultiplier);
    /// @notice Emited when the voting multiplier for creating proposals is changed
    event ProposalsCreatedMultiplierChanged(uint64 _proposalsCreatedMultiplier);
    /// @notice Emited when the base votes for a token is changed
    event BaseVotesChanged(uint256 _baseVotes);

    /////////////////////
    ////// Storage //////
    /////////////////////

    struct CommunityPowerMultipliers {
        uint64 votes;
        uint64 proposalsCreated;
        uint64 proposalsPassed;
    }

    struct StakingSettings {
        uint128 maxStakeBonusTime;
        uint128 maxStakeBonusAmount;
    }

    enum RefundStatus { 
        StakingAndDelegatingRefund,
        StakingRefund, 
        DelegatingRefund, 
        NoRefunds
    }

    /////////////////////
    ////// Methods //////
    /////////////////////

    function baseTokenURI() external view returns (string memory);
    function BASE_VOTES() external view returns (uint256);
    function changeStakeAmount(uint128 _newMaxStakeBonusAmount) external;
    function changeStakeTime(uint128 _newMaxStakeBonusTime) external;
    function communityPowerMultipliers()
        external
        view
        returns (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed);
    function delegate(address _delegatee) external;
    function delegatingRefund() external view returns (bool);
    function evilBonus(uint256 _tokenId) external view returns (uint256);
    function getCommunityVotingPower(address _voter) external view returns (uint256);
    function getDelegate(address _delegator) external view returns (address);
    function getStakedTokenSupplies() external view returns (uint128, uint128);
    function getTokenVotingPower(uint256 _tokenId) external view returns (uint256);
    function getTotalVotingPower() external view returns (uint256);
    function getVotes(address _account) external view returns (uint256);
    function isFrankenPunksStakingContract() external pure returns (bool);
    function lastDelegatingRefund(address) external view returns (uint256);
    function lastStakingRefund(address) external view returns (uint256);
    function paused() external view returns (bool);
    function setBaseURI(string memory _baseURI) external;
    function setPause(bool _paused) external;
    function setProposalsCreatedMultiplier(uint64 _proposalsCreatedMultiplier) external;
    function setProposalsPassedMultiplier(uint64 _proposalsPassedMultiplier) external;
    function setRefunds(bool _stakingRefund, bool _delegatingRefund, uint256 _newCooldown) external;
    function setVotesMultiplier(uint64 _votesmultiplier) external;
    function stake(uint256[] memory _tokenIds, uint256 _unlockTime) external;
    function stakedFrankenMonsters() external view returns (uint128);
    function stakedFrankenPunks() external view returns (uint128);
    function stakingRefund() external view returns (bool);
    function stakingSettings() external view returns (uint128 maxStakeBonusTime, uint128 maxStakeBonusAmount);
    function tokenVotingPower(address) external view returns (uint256);
    function unlockTime(uint256) external view returns (uint256);
    function unstake(uint256[] memory _tokenIds, address _to) external;
    function votesFromOwnedTokens(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../interfaces/IAdmin.sol";
import "../interfaces/IExecutor.sol";
import { FrankenDAOErrors } from "../errors/FrankenDAOErrors.sol";

/// @notice Custom access control manager for FrankenDAO
/// @dev This functionality is inherited by Governance.sol and Staking.sol
abstract contract Admin is IAdmin, FrankenDAOErrors {
    /// @notice Founder multisig
    address public founders;

    /// @notice Council multisig
    address public council;

    /// @notice Executor contract address for passed governance proposals
    IExecutor public executor;

    /// @notice Admin that only has the power to pause and unpause staking
    /// @dev This will be a EOA used by the team for easy pausing and unpausing
    /// @dev This address is changeable by governance if the community thinks the team is misusing this power
    address public pauser;

    /// @notice Admin that only has the power to verify contracts
    /// @dev This will be an EOA used by the team for contract verification
    address public verifier;

    /// @notice Pending founder addresses for this contract
    /// @dev Only founders is two-step, because errors in transferring other admin addresses can be corrected by founders
    address public pendingFounders;

    /////////////////////////////
    ///////// MODIFIERS /////////
    /////////////////////////////

    /// @notice Modifier for functions that can only be called by the Executor contract
    /// @dev This is for functions that only Governance is able to call
    modifier onlyExecutor() {
        if(msg.sender != address(executor)) revert NotAuthorized();
        _;
    }

    /// @notice Modifier for functions that can only be called by the Council or Founder multisigs
    modifier onlyAdmins() {
        if(msg.sender != founders && msg.sender != council) revert NotAuthorized();
        _;
    }

    /// @notice Modifier for functions that can only be called by the Pauser or either multisig
    modifier onlyPauserOrAdmins() {
        if(msg.sender != founders && msg.sender != council && msg.sender != pauser) revert NotAuthorized();
        _;
    }

    modifier onlyVerifierOrAdmins() {
        if(msg.sender != founders && msg.sender != council && msg.sender != verifier) revert NotAuthorized();
        _;
    }

    /// @notice Modifier for functions that can only be called by either multisig or the Executor contract
    modifier onlyExecutorOrAdmins() {
        if (
            msg.sender != address(executor) && 
            msg.sender != council && 
            msg.sender != founders
        ) revert NotAuthorized();
        _;
    }

    /////////////////////////////
    ////// ADMIN TRANSFERS //////
    /////////////////////////////

    /// @notice Begins transfer of founder rights. The newPendingFounders must call `_acceptFounders` to finalize the transfer.
    /// @param _newPendingFounders New pending founder.
    /// @dev This doesn't use onlyAdmins because only Founders have the right to set new Founders.
    function setPendingFounders(address _newPendingFounders) external {
        if (msg.sender != founders) revert NotAuthorized();
        emit NewPendingFounders(pendingFounders, _newPendingFounders);
        pendingFounders = _newPendingFounders;
    }

    /// @notice Accepts transfer of founder rights. msg.sender must be pendingFounders
    function acceptFounders() external {
        if (msg.sender != pendingFounders) revert NotAuthorized();
        emit NewFounders(founders, pendingFounders);
        founders = pendingFounders;
        pendingFounders = address(0);
    }

    /// @notice Revokes permissions for the founder multisig
    /// @dev Only the founders can call this, as nobody else should be able to revoke this permission
    /// @dev Used for eventual decentralization, as otherwise founders cannot be set to address(0) because of two-step
    /// @dev This also ensures that pendingFounders is set to address(0), to ensure they can't re-accept it later
    function revokeFounders() external {
        if (msg.sender != founders) revert NotAuthorized();
        
        emit NewFounders(founders, address(0));
        
        founders = address(0);
        pendingFounders = address(0);
    }

    /// @notice Transfers council address to a new multisig
    /// @param _newCouncil New address for council
    /// @dev This uses onlyAdmin because either the Council or the Founders can set a new Council.
    function setCouncil(address _newCouncil) external onlyAdmins {
       
        emit NewCouncil(council, _newCouncil);
       
        council = _newCouncil;
    }

    /// @notice Transfers verifier role to a new address.
    /// @param _newVerifier New address for verifier
    function setVerifier(address _newVerifier) external onlyAdmins {

        emit NewVerifier(verifier, _newVerifier);
        
        verifier = _newVerifier;
    }

    /// @notice Transfers pauser role to a new address.
    /// @param _newPauser New address for pauser
    function setPauser(address _newPauser) external onlyExecutorOrAdmins {
        
        emit NewPauser(pauser, _newPauser);
        
        pauser = _newPauser;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../interfaces/IRefundable.sol";
import { FrankenDAOErrors } from "../errors/FrankenDAOErrors.sol";

/// @notice Provides a _refundGas() function that can be used for inhering contracts to refund user gas cost
/// @dev This functionality is inherited by Governance.sol (for proposing and voting) and Staking.sol (for staking and delegating)
contract Refundable is IRefundable, FrankenDAOErrors {

    /// @notice The maximum priority fee used to cap gas refunds
    uint256 public constant MAX_REFUND_PRIORITY_FEE = 2 gwei;

    /// @notice Gas used before _startGas or after refund
    /// @dev Includes 21K TX base, 3.7K for other overhead, and 2.3K for ETH transfer 
    /** @dev This will be slightly different depending on which function is used, but all are within a few 
        thousand gas, so approximation is fine. */
    uint256 public constant REFUND_BASE_GAS = 27_000;

    /// @notice Calculate the amount spent on gas and send that to msg.sender from the contract's balance
    /// @param _startGas gasleft() at the start of the transaction, used to calculate gas spent
    /// @dev Forked from NounsDAO: https://github.com/nounsDAO/nouns-monorepo/blob/master/packages/nouns-contracts/contracts/governance/NounsDAOLogicV2.sol#L1033-L1046
    function _refundGas(uint256 _startGas) internal {
        unchecked {
            uint256 gasPrice = _min(tx.gasprice, block.basefee + MAX_REFUND_PRIORITY_FEE);
            uint256 gasUsed = _startGas - gasleft() + REFUND_BASE_GAS;
            uint refundAmount = gasPrice * gasUsed;
            
            // If gas fund runs out, pay out as much as possible and emit warning event.
            if (address(this).balance < refundAmount) {
                emit InsufficientFundsForRefund(msg.sender, refundAmount, address(this).balance);
                refundAmount = address(this).balance;
            }

            // There shouldn't be any reentrancy risk, as this is called last at all times.
            // They also can't exploit the refund by wasting gas before we've already finalized amount.
            (bool refundSent, ) = msg.sender.call{ value: refundAmount }('');

            // Includes current balance in event so team can listen and filter to know when to propose refill.
            emit IssueRefund(msg.sender, refundAmount, refundSent, address(this).balance);
        }
    }

    /// @notice Returns the lower value of two uints
    /// @param a First uint
    /// @param b Second uint
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }
}