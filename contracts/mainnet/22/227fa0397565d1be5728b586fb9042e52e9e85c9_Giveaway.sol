/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

pragma solidity ^0.8.0;

abstract contract VRFConsumerBase is VRFRequestIDBase {

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

 
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.0;

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;


    function setApprovalForAll(address operator, bool _approved) external;


    function getApproved(uint256 tokenId) external view returns (address operator);


    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

pragma solidity ^0.8.4;

abstract contract Guilds {
    struct Guild {
        uint256 TokenId;
        string GuildName;
        string GuildDesc;
        address Admin;
        address[] GuildMembers;
        address[] GuildMods;
        string GuildType;
        uint256[] Appeals;
        uint256 UnlockDate;
        uint256 LockDate;
        string GuildRules;
        bool FreezeMetaData;
        address[] Kicked;
    }

    function getGuildById(uint256 _id) external virtual view returns (Guild memory guild);

    function balanceOf(address account, uint256 id)
        external
        virtual
        view
        returns (uint256);

    function totalSupply(uint256 id) public view virtual returns (uint256);
}

pragma solidity ^0.8.4;

contract Giveaway is ReentrancyGuard, VRFConsumerBase {
    Guilds private guilds;

    struct Raffle {
        uint256 GuildId;
        uint256 TotalEntries;
        address Staker;
        IERC721 StakedCollection;
        uint256 StakedTokenId;
    }

    mapping(uint256 => Raffle) raffle;
    mapping(uint256 => bool) raffleExists;
    address GuildsAddress = 0x9c26d327435148dE06c53A014103A7a3c82c672f;
    string private _name;
    string private _symbol;
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 private randomResult;

    constructor(string memory _name_, string memory _symbol_) 
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B,
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 
        )
    {
        _name = _name_;
        _symbol = _symbol_;
        guilds = Guilds(GuildsAddress); 
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10 ** 18;
    }

  Guilds.Guild guild;

    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        randomResult = randomness;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    } 

    function stake(uint256 _tokenId, IERC721 nftCollection, uint256 _guildId, uint256 _spots) external nonReentrant {
        Guilds.Guild memory _guild = guilds.getGuildById(_guildId);
        require(!raffleExists[_guildId], "Each guild can have only one giveaway at a time");
        require(_guild.Admin == msg.sender, "Only guild master can start a giveaway");
        require(guilds.totalSupply(_guildId) >= _spots, "Not enough spots to giveaway");
        require(
            nftCollection.ownerOf(_tokenId) == msg.sender,
            "You don't own this token!"
        );

        nftCollection.transferFrom(msg.sender, address(this), _tokenId);
        raffle[_guildId].GuildId = _guildId;
        raffle[_guildId].TotalEntries = _spots;
        raffle[_guildId].Staker = msg.sender;
        raffle[_guildId].StakedCollection = nftCollection;
        raffle[_guildId].StakedTokenId = _tokenId;
        raffleExists[_guildId] = true;
    }

    function reward(uint256 _guildId) external nonReentrant {
        require(raffleExists[_guildId], "Raffle is not existed");
        address[] memory totalEntries = countEntries(_guildId);
        for (uint i; i < totalEntries.length; i++) {
            if (totalEntries[i] == address(0)) {
                revert("Giveaway is not finished");
            }
        }

        require(randomResult > 0, "No random number to give, get random number and wait for oracle to finish randomness");
        uint256 winnerIndex = (randomResult % raffle[_guildId].TotalEntries);
        address winner = totalEntries[winnerIndex];
        raffle[_guildId].StakedCollection.transferFrom(address(this), winner, raffle[_guildId].StakedTokenId);
        delete raffle[_guildId];
        raffleExists[_guildId] = false;
        randomResult = 0;
    }

    function totalEntriesOfRaffle(uint256 _guildId) public view returns(uint256) {
        return raffle[_guildId].TotalEntries;
    }

    function rewardToken(uint256 _guildId) public view returns(uint256) {
        return raffle[_guildId].StakedTokenId;
    }

    function rewardCollection(uint256 _guildId) public view returns(IERC721) {
        return raffle[_guildId].StakedCollection;
    }


    function countEntries(uint256 _guildId)
        public
        view
        returns (address[] memory)
    {
        Guilds.Guild memory _guild = guilds.getGuildById(_guildId);
        uint maxSpots = raffle[_guildId].TotalEntries;
        address[] memory participants = new address[](maxSpots);
        uint256 lastIndexFilled;

        if (_guild.GuildMembers.length > 0) {
        for (uint i; i < _guild.GuildMembers.length; i++) {
            if (_guild.GuildMembers[i] != address(0)) {
                 uint256 _entriesForAddress = guilds.balanceOf(
                    _guild.GuildMembers[i],
                    _guildId
                );
                for (uint256 x; x < _entriesForAddress; x++) {
                    uint indexToUpdate = x + lastIndexFilled;
                    if (indexToUpdate < maxSpots) {
                    participants[indexToUpdate] = _guild.GuildMembers[i];
                    }
                } 
                lastIndexFilled += _entriesForAddress;  
            }             
        }
        }

        if (_guild.GuildMods.length > 0) {
        for (uint i; i < _guild.GuildMods.length; i++) {
            if (_guild.GuildMods[i] != address(0)) {
                 uint256 _entriesForAddress = guilds.balanceOf(
                    _guild.GuildMods[i],
                    _guildId
                );
                for (uint256 x; x < _entriesForAddress; x++) {
                    uint indexToUpdate = x + lastIndexFilled;
                    if (indexToUpdate < maxSpots) {
                    participants[indexToUpdate] = _guild.GuildMods[i];
                    }
                } 
                lastIndexFilled += _entriesForAddress; 
            }    
        }
        }

        return participants;
    }


    function indexOfAddress(address[] memory arr, address searchFor)
        private
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == searchFor) {
                return i;
            }
        }
        revert("Address Not Found");
    }

}