// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
import "ERC20.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////    WHITE LIST
///////////////////////////    WHITE LIST
///////////////////////////    WHITE LIST

contract MythWhiteList {
    //This contract is the Liquidity Pool, the balance of this SC is the LP

    //mapping from address to string nickname
    mapping(address => string) public mythNickNames;
    mapping(address => string) public mythPFPUrl;
    //mapping from string to true/false
    mapping(string => bool) public activeNickNames;
    mapping(string => bool) public takenAffiliateCodeNames;
    mapping(string => address) public addressOfAffiliateCodeNames;
    mapping(address => string) public codeNameFromAddress;
    //mapping from address to claimed bnb from lp
    mapping(address => uint256) public totalLPClaimed;
    //mapping from affiliate address to total rewards
    mapping(address => uint256) public totalAffiliateRewards;
    //mapping from address to true/false (whitelisted)
    mapping(address => bool) public whitelist;
    //mapping from user address to affiliate address
    mapping(address => address) public affiliateAddress;
    mapping(address => bool) public partnerAddress;
    //myth contract
    Utilitytoken public mythContract;
    //contract name
    string public name = "Myth WhiteList";
    //owner address
    address payable public owner;
    address public marketingWallet;

    enum BetState {
        PLACED,
        INITIALIZED,
        RESOLVED,
        CANCELLED
    }
    enum BetType {
        COINFLIP,
        DICEDUEL,
        DEATHROLL,
        OTHER
    }
    //EVENTS
    event whitelistAdded(address _address);
    event whitelistRemoved(address _address);

    event betPlaced(
        address gameAddress,
        address better,
        uint256 amount,
        uint256 betId,
        uint8 side,
        string betterNickName
    );
    event betCalled(
        address gameAddress,
        address caller,
        uint256 blockInitialized,
        uint256 betId,
        string callerNickName,
        address better
    );
    event betResolved(
        address gameAddress,
        bytes32 resolutionSeed,
        bool betterWinner,
        uint256 betId,
        address better,
        address caller
    );
    event betCancelled(address gameAddress, uint256 betId, address better);

    function emitBetResolved(
        bytes32 resolutionSeed,
        bool betterWinner,
        uint256 betId,
        address better,
        address caller
    ) external returns (bool) {
        require(
            whitelist[msg.sender],
            "Only whitelisted addresses can emit events"
        );
        emit betResolved(
            msg.sender,
            resolutionSeed,
            betterWinner,
            betId,
            better,
            caller
        );
        return true;
    }

    function emitBetCancelled(uint256 betId, address better)
        external
        returns (bool)
    {
        require(
            whitelist[msg.sender],
            "Only whitelisted addresses can emit events"
        );
        emit betCancelled(msg.sender, betId, better);
        return true;
    }

    function emitBetPlaced(
        address better,
        uint256 amount,
        uint256 betId,
        uint8 side
    ) external returns (bool) {
        require(
            whitelist[msg.sender],
            "Only whitelisted addresses can emit events"
        );
        emit betPlaced(
            msg.sender,
            better,
            amount,
            betId,
            side,
            mythNickNames[better]
        );
        return true;
    }

    function emitBetCalled(
        address caller,
        uint256 blockInitialized,
        uint256 betId,
        address better
    ) external returns (bool) {
        require(
            whitelist[msg.sender],
            "Only whitelisted addresses can emit events"
        );
        emit betCalled(
            msg.sender,
            caller,
            blockInitialized,
            betId,
            mythNickNames[caller],
            better
        );
        return true;
    }

    function emitBetPlacedCalled(
        address better,
        uint256 amount,
        uint256 betId,
        uint8 side,
        address caller,
        uint256 blockInitialized
    ) external returns (bool) {
        require(
            whitelist[msg.sender],
            "Only whitelisted addresses can emit events"
        );
        emit betPlaced(
            msg.sender,
            better,
            amount,
            betId,
            side,
            mythNickNames[better]
        );
        emit betCalled(
            msg.sender,
            caller,
            blockInitialized,
            betId,
            mythNickNames[caller],
            better
        );
        return true;
    }

    //constructor
    constructor() {
        owner = payable(msg.sender);
        mythNickNames[address(0)] = "BOB";
        mythPFPUrl[
            address(0)
        ] = "https://imgs.search.brave.com/7VYNMq4_ZlrBRj-aejnye5b_4Y0NX813goCpglRRHJM/rs:fit:570:640:1/g:ce/aHR0cHM6Ly9tZWxt/YWdhemluZS5jb20v/d3AtY29udGVudC91/cGxvYWRzLzIwMjEv/MDEvNjZmLTEtNTcw/eDY0MC5qcGc";
        marketingWallet = msg.sender;
    }

    function updateBob(string calldata url, string calldata name) external {
        require(msg.sender == owner, "only owner can update bob");
        mythNickNames[address(0)] = name;
        mythPFPUrl[address(0)] = url;
    }

    function setPFPUrl(string calldata url) external {
        mythPFPUrl[msg.sender] = url;
    }

    function setPFPUrlOverride(string calldata url, address _address) external {
        require(
            msg.sender == owner,
            "only the owner can override pfp pictures"
        );
        mythPFPUrl[_address] = url;
    }

    //function that allows a user to set their affiliate address
    function setAffiliate(address _address) external {
        affiliateAddress[msg.sender] = _address;
    }

    function setAffiliateByName(string calldata codeName) external {
        require(
            addressOfAffiliateCodeNames[codeName] != address(0),
            "CodeName Doesnt Exist"
        );
        affiliateAddress[msg.sender] = addressOfAffiliateCodeNames[codeName];
    }

    function setCodeName(string calldata codeName) external {
        require(
            takenAffiliateCodeNames[codeName] == false,
            "Name already used"
        );

        delete takenAffiliateCodeNames[codeNameFromAddress[msg.sender]];
        delete addressOfAffiliateCodeNames[codeNameFromAddress[msg.sender]];
        codeNameFromAddress[msg.sender] = codeName;

        takenAffiliateCodeNames[codeName] = true;
        addressOfAffiliateCodeNames[codeName] = msg.sender;
    }

    function updatePartner(address _address) external {
        require(msg.sender == owner, "Only the owner can give parters");
        partnerAddress[_address] = !partnerAddress[_address];
    }

    function changeMarketingWallet(address _address) external {
        require(
            msg.sender == owner,
            "Only the owner can change marketing Wallet"
        );
        marketingWallet = _address;
    }

    //function that is called from smart contracts to manage total rewards for affiliate address
    function addAffiliateRewards(address _address, uint256 _amount) external {
        require(
            whitelist[msg.sender],
            "Only whitelisted addresses can add affiliate rewards"
        );
        totalAffiliateRewards[_address] += _amount;
    }

    //function that allows users to set a new nickname for their address
    function setNickName(string memory _newName) external {
        require(activeNickNames[_newName] == false, "Name already used");
        activeNickNames[_newName] = true;
        activeNickNames[mythNickNames[msg.sender]] = false;
        mythNickNames[msg.sender] = _newName;
    }

    //function for the owner address to set address of myth erc20
    function setMythAddress(address _address) external {
        require(msg.sender == owner, "Only owner can set Myth Address");
        mythContract = Utilitytoken(_address);
    }

    //function that other SC call to send ETHER to the LP
    function recieve() external payable {}

    //function for users to claim their myth, myth is burned while BNB is sent from the LP to the user
    function redeemMythTokens(uint256 _amount) external {
        uint256 totalSupply = mythContract.totalSupply();
        require(
            _amount <= mythContract.balanceOf(msg.sender),
            "You dont have enough myth to claim"
        );
        require(_amount >= 10000000, "Must claim more myth");
        uint256 claimableRewards = ((_amount * 1e18) / totalSupply) *
            address(this).balance;
        mythContract.burn(msg.sender, _amount);
        payable(msg.sender).transfer(claimableRewards / 1e18);
        totalLPClaimed[msg.sender] += claimableRewards / 1e18;
    }

    //function that simply returns Ether balance of this SC
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    //function that only owner can call. Adds address to whitelist, these will be the SC games made later on
    function addToWhiteList(address _address) external {
        require(msg.sender == owner, "Only owner can whitelist an address");
        require(!whitelist[_address], "This address is already whitelisted");
        whitelist[_address] = true;
        emit whitelistAdded(_address);
    }

    //function that only owner can call. Removes address from whitelist, these will be the SC games made later on
    function removeFromWhiteList(address _address) external {
        require(msg.sender == owner, "Only owner can whitelist an address");
        require(whitelist[_address], "This address is already not whitelisted");
        whitelist[_address] = false;
        emit whitelistRemoved(_address);
    }

    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        owner.transfer(address(this).balance);
    }

    //read only function to recieve affiliate percent
    function getAffiliatePercent(address _address) public view returns (bool) {
        return partnerAddress[affiliateAddress[_address]];
    }
}

///////////////////////////    WHITE LIST
///////////////////////////    WHITE LIST
///////////////////////////    WHITE LIST

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////     MYTH TOKEN
///////////////////////////     MYTH TOKEN
///////////////////////////     MYTH TOKEN
contract Utilitytoken is ERC20 {
    //This contract is the Myth Token ERC20

    address payable public owner;
    address public marketingWallet;
    MythWhiteList public whitelist;
    mapping(address => uint256) public totalMythMinted;
    mapping(address => uint256) public totalMythBurned;
    mapping(address => uint256) public totalMythMintedPerAddress;

    constructor(
        address _address,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        owner = payable(msg.sender);
        marketingWallet = msg.sender;
        whitelist = MythWhiteList(_address);
    }

    //This function can only be called by whitelisted address but not the owner
    function mint(address to, uint256 amount) external {
        require(
            whitelist.whitelist(msg.sender) == true && msg.sender != owner,
            "Only whitelisted address can mint tokens"
        );
        _mint(to, amount);
        totalMythMintedPerAddress[to] += amount;
        totalMythMinted[to] += amount;
    }

    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        owner.transfer(address(this).balance);
    }

    function recieve() external payable {}

    function changeMarketingWallet(address _address) external {
        require(
            msg.sender == owner,
            "Only the owner can change marketing Wallet"
        );
        marketingWallet = _address;
    }

    function mintMythForRewards(uint256 rewardAmount, address _address)
        external
        returns (bool)
    {
        require(
            whitelist.whitelist(msg.sender) == true && msg.sender != owner,
            "Only whitelisted addresses can mint bets"
        );
        uint256 mintUnit = SafeMath.div(rewardAmount, 1000);
        _mint(owner, mintUnit * 20);
        uint256 marketShare = 10;
        if (whitelist.getAffiliatePercent(_address)) {
            _mint(_address, mintUnit * 6);
            _mint(whitelist.affiliateAddress(_address), mintUnit * 4);
        } else {
            _mint(_address, mintUnit * 5);
            marketShare += 5;
        }
        _mint(marketingWallet, mintUnit * marketShare);
        return true;
    }

    // function mintMythForBet(
    //     uint256 betAmount,
    //     address better,
    //     address caller
    // ) external returns (bool) {
    //     require(
    //         whitelist.whitelist(msg.sender) == true && msg.sender != owner,
    //         "Only whitelisted addresses can mint bets"
    //     );
    //     uint256 mintUnit = SafeMath.div(betAmount, 1000);

    //     _mint(owner, mintUnit * 20);
    //     uint256 marketShare = 10;
    //     if (whitelist.getAffiliatePercent(better)) {
    //         _mint(better, mintUnit * 6);
    //         _mint(whitelist.affiliateAddress(better), mintUnit * 4);
    //     } else {
    //         _mint(better, mintUnit * 5);
    //         marketShare += 5;
    //     }
    //     if (caller == address(0)) {
    //         marketShare += 10;
    //     } else {
    //         if (whitelist.getAffiliatePercent(caller)) {
    //             _mint(caller, mintUnit * 6);
    //             _mint(whitelist.affiliateAddress(caller), mintUnit * 4);
    //         } else {
    //             _mint(caller, mintUnit * 5);
    //             marketShare += 5;
    //         }
    //     }
    //     _mint(marketingWallet, mintUnit * marketShare);
    //     return true;
    // }

    //This function can only be called by whitelisted address but not the owner
    function burn(address to, uint256 amount) external {
        require(
            whitelist.whitelist(msg.sender) == true && msg.sender != owner,
            "Only whitelisted address can burn tokens"
        );
        _burn(to, amount);
        totalMythBurned[to] += amount;
    }
}

///////////////////////////     MYTH TOKEN
///////////////////////////     MYTH TOKEN
///////////////////////////     MYTH TOKEN

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////     COIN FLIP
///////////////////////////     COIN FLIP
///////////////////////////     COIN FLIP

contract MythCoinFlip {
    address payable public owner;
    MythWhiteList public whitelist;
    Utilitytoken public mythContract;

    string public name = "Myth Coin Flip";

    uint256 public minBet = 3 * (10**16);
    uint256 public maxBet = 2 * (10**18);
    uint256 public bobBalance;

    mapping(address => uint256) public totalClaimedRewardsAddress;
    mapping(address => uint256) public totalBetsPlaced;
    mapping(address => uint256) public rewardBalances;
    mapping(uint256 => betStructure) public placedBets;
    mapping(uint256 => uint256) public betCountsPerBlock;
    mapping(uint256 => mapping(uint256 => uint256)) public noncePerBlock;
    mapping(uint256 => bool) public resolvedBlocks;

    uint256 public betCount;
    uint256 public pendingBets;

    enum BetState {
        PLACED,
        INITIALIZED,
        RESOLVED,
        CANCELLED
    }

    struct betStructure {
        address better;
        address caller;
        BetState betState;
        uint256 amount;
        uint256 blockNumberInitialized;
        bytes32 resolutionSeed;
        bool betterWinner;
        uint8 betterSide;
    }

    constructor(address _whitelist, address _myth) {
        whitelist = MythWhiteList(_whitelist);
        mythContract = Utilitytoken(_myth);
        owner = payable(msg.sender);
        betCount = 0;
        resolvedBlocks[0] = true;
    }

    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        owner.transfer(address(this).balance);
        bobBalance = 0;
    }

    // Function for players to place bets
    function placeBet(bool _pvp, uint8 _side) external payable {
        require(msg.value >= minBet, "Too little of bet");
        //If pvp is false then the user wants to VS the BOB (HOUSE)
        uint256 _betCount = betCount;
        if (!_pvp) {
            require(msg.value <= maxBet, "Too Big of a bet for Bob");
            require(
                msg.value <= bobBalance,
                "Bob does not have enough right now to cover bet"
            );
            bobBalance -= msg.value;
            placedBets[_betCount].better = msg.sender;
            placedBets[_betCount].betState = BetState.INITIALIZED;
            placedBets[_betCount].amount = msg.value;
            placedBets[_betCount].blockNumberInitialized = block.number;
            placedBets[_betCount].betterSide = _side;
            noncePerBlock[block.number][
                betCountsPerBlock[block.number]
            ] = betCount;
            betCountsPerBlock[block.number] += 1;
            whitelist.emitBetPlacedCalled(
                msg.sender,
                msg.value,
                betCount,
                _side,
                address(0),
                block.number
            );
            totalBetsPlaced[msg.sender] += msg.value;
            betCount++;
        } else {
            placedBets[_betCount].better = msg.sender;
            placedBets[_betCount].amount = msg.value;
            placedBets[_betCount].betterSide = _side;
            totalBetsPlaced[msg.sender] += msg.value;
            whitelist.emitBetPlaced(msg.sender, msg.value, betCount, _side);
            betCount++;
            pendingBets++;
        }
    }

    //Function to cancel bets
    function cancelBet(uint256 _betId) external payable {
        require(msg.value == 0, "Don't send money to cancel a bet");
        require(
            placedBets[_betId].betState == BetState.PLACED,
            "Only placed bets can be cancelled"
        );
        require(
            placedBets[_betId].better == msg.sender,
            "Only the one who placed this bet can cancel it"
        );
        totalBetsPlaced[msg.sender] -= placedBets[_betId].amount;
        placedBets[_betId].betState = BetState.CANCELLED;
        (bool successUser, ) = msg.sender.call{
            value: placedBets[_betId].amount
        }("");
        require(successUser, "Transfer to user failed");
        pendingBets--;

        whitelist.emitBetCancelled(_betId, msg.sender);
    }

    //Function for players to call someone elses coinflip
    function callBet(uint256 _betId) external payable {
        require(
            placedBets[_betId].betState == BetState.PLACED,
            "Only placed bets can be called"
        );
        require(
            placedBets[_betId].amount == msg.value,
            "Send exact bet amount"
        );
        placedBets[_betId].caller = msg.sender;
        placedBets[_betId].betState = BetState.INITIALIZED;
        placedBets[_betId].blockNumberInitialized = block.number;
        noncePerBlock[block.number][betCountsPerBlock[block.number]] = _betId;
        betCountsPerBlock[block.number] += 1;
        pendingBets--;
        totalBetsPlaced[msg.sender] += msg.value;
        whitelist.emitBetCalled(
            msg.sender,
            block.number,
            _betId,
            placedBets[_betId].better
        );
    }

    function backupResolve(uint256 betId, bytes32 _resolutionSeed) external {
        require(msg.sender == owner, "Only owner can resolve bets");
        betStructure memory currentBet = placedBets[betId];
        require(currentBet.betState == BetState.INITIALIZED);
        currentBet.resolutionSeed = _resolutionSeed;
        currentBet.betState = BetState.RESOLVED;
        currentBet.betterWinner = resolveFlip(
            _resolutionSeed,
            betId,
            currentBet.betterSide
        );
        if (currentBet.betterWinner) {
            rewardBalances[currentBet.better] += currentBet.amount * 2;
        } else {
            if (currentBet.caller != address(0)) {
                rewardBalances[currentBet.caller] += currentBet.amount * 2;
            } else {
                bobBalance += currentBet.amount * 2;
            }
        }
        placedBets[betId] = currentBet;
        whitelist.emitBetResolved(
            _resolutionSeed,
            currentBet.betterWinner,
            betId,
            currentBet.better,
            currentBet.caller
        );
    }

    //Function to resolve Initialized bets
    function resolveBet(uint256 _blockNumber, bytes32 _resolutionSeed)
        external
    {
        require(msg.sender == owner, "Only owner can resolve bets");
        require(
            resolvedBlocks[_blockNumber] == false,
            "Block Number Already Resolved"
        );

        uint256 betCountOfBlock = betCountsPerBlock[_blockNumber];
        uint256 counter = 0;
        resolvedBlocks[_blockNumber] = true;
        while (counter < betCountOfBlock) {
            betStructure memory currentBet = placedBets[
                noncePerBlock[_blockNumber][counter]
            ];
            if (currentBet.betState != BetState.INITIALIZED) {
                continue;
            }
            currentBet.resolutionSeed = _resolutionSeed;
            currentBet.betState = BetState.RESOLVED;
            currentBet.betterWinner = resolveFlip(
                _resolutionSeed,
                noncePerBlock[_blockNumber][counter],
                currentBet.betterSide
            );
            if (currentBet.betterWinner) {
                rewardBalances[currentBet.better] += currentBet.amount * 2;
            } else {
                if (currentBet.caller != address(0)) {
                    rewardBalances[currentBet.caller] += currentBet.amount * 2;
                } else {
                    bobBalance += currentBet.amount * 2;
                }
            }
            placedBets[noncePerBlock[_blockNumber][counter]] = currentBet;
            whitelist.emitBetResolved(
                _resolutionSeed,
                currentBet.betterWinner,
                noncePerBlock[_blockNumber][counter],
                currentBet.better,
                currentBet.caller
            );
            counter++;
        }
    }

    //Internal function to find a winner of a dice duel
    function resolveFlip(
        bytes32 _resolutionSeed,
        uint256 nonce,
        uint8 _side
    ) internal view returns (bool) {
        uint8 roll = uint8(
            uint256(keccak256(abi.encodePacked(_resolutionSeed, nonce))) % 2
        );
        return roll == _side;
    }

    //Function for setting bet limits
    function setMinMax(uint256 _minBet, uint256 _maxBet) external {
        require(msg.sender == owner, "Only owner can set min bet");
        minBet = _minBet;
        maxBet = _maxBet;
    }

    //Function to call BOB
    function callBob(uint256 _betId) external {
        require(
            placedBets[_betId].better == msg.sender,
            "Only better can call Bob"
        );
        require(
            placedBets[_betId].betState == BetState.PLACED,
            "only placed bets can call bob"
        );
        require(
            placedBets[_betId].amount <= bobBalance,
            "Bob doesn't have enough to cover bet"
        );
        require(placedBets[_betId].amount <= maxBet, "Bet is above Max Bet");
        bobBalance -= placedBets[_betId].amount;
        placedBets[_betId].betState = BetState.INITIALIZED;
        placedBets[_betId].blockNumberInitialized = block.number;
        noncePerBlock[block.number][betCountsPerBlock[block.number]] = _betId;
        betCountsPerBlock[block.number] += 1;
        pendingBets--;
        whitelist.emitBetCalled(address(0), block.number, _betId, msg.sender);
    }

    //Function to claim winnings
    function withdrawWinnings() external payable {
        require(msg.value == 0, "Dont send bnb");
        require(
            rewardBalances[msg.sender] <= address(this).balance,
            "Smart Contract Doesnt have enough funds"
        );
        uint256 rewardsForPlayer = rewardBalances[msg.sender];
        rewardBalances[msg.sender] = 0;
        uint256 rewardPerCent = ((rewardsForPlayer -
            (rewardsForPlayer % 10000)) / 100);
        whitelist.recieve{value: rewardPerCent * 5}();
        (bool successUser, ) = msg.sender.call{value: (rewardPerCent * 95)}("");
        require(successUser, "Transfer to user failed");
        bool successMyth = mythContract.mintMythForRewards(
            rewardsForPlayer,
            msg.sender
        );
        require(successMyth, "Myth Minted");
        totalClaimedRewardsAddress[msg.sender] += rewardPerCent * 95;
    }

    function depoBob() external payable {
        require(msg.sender == owner, "Only the owner can load bob");
        bobBalance += msg.value;
    }
}

///////////////////////////     COIN FLIP
///////////////////////////     COIN FLIP
///////////////////////////     COIN FLIP

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////     DICE DUEL
///////////////////////////     DICE DUEL
///////////////////////////     DICE DUEL

contract MythDiceDuel {
    address payable public owner;
    MythWhiteList public whitelist;
    Utilitytoken public mythContract;

    string public name = "Myth Dice Duel";

    uint256 public minBet = 3 * (10**16);
    uint256 public maxBet = 2 * (10**18);
    uint256 public bobBalance;

    mapping(address => uint256) public totalClaimedRewardsAddress;
    mapping(address => uint256) public totalBetsPlaced;
    mapping(address => uint256) public rewardBalances;
    mapping(uint256 => betStructure) public placedBets;
    mapping(uint256 => uint256) public betCountsPerBlock;
    mapping(uint256 => mapping(uint256 => uint256)) public noncePerBlock;
    mapping(uint256 => bool) public resolvedBlocks;

    uint256 public betCount;
    uint256 public pendingBets;

    enum BetState {
        PLACED,
        INITIALIZED,
        RESOLVED,
        CANCELLED
    }

    struct betStructure {
        address better;
        address caller;
        BetState betState;
        uint256 amount;
        uint256 blockNumberInitialized;
        bytes32 resolutionSeed;
        bool betterWinner;
    }

    constructor(address _whitelist, address _myth) {
        whitelist = MythWhiteList(_whitelist);
        mythContract = Utilitytoken(_myth);
        owner = payable(msg.sender);
        betCount = 0;
    }

    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        owner.transfer(address(this).balance);
        bobBalance = 0;
    }

    // Function for players to place bets
    function placeBet(bool _pvp) external payable {
        require(msg.value >= minBet, "Too little of bet");
        //If pvp is false then the user wants to VS the BOB (HOUSE)
        uint256 _betCount = betCount;
        if (!_pvp) {
            require(msg.value <= maxBet, "Too Big of a bet for Bob");
            require(
                msg.value <= bobBalance,
                "Bob does not have enough to cover bet"
            );
            totalBetsPlaced[msg.sender] += msg.value;
            bobBalance -= msg.value;
            placedBets[_betCount].better = msg.sender;
            placedBets[_betCount].betState = BetState.INITIALIZED;
            placedBets[_betCount].amount = msg.value;
            placedBets[_betCount].blockNumberInitialized = block.number;
            noncePerBlock[block.number][
                betCountsPerBlock[block.number]
            ] = betCount;
            betCountsPerBlock[block.number] += 1;
            whitelist.emitBetPlacedCalled(
                msg.sender,
                msg.value,
                betCount,
                2,
                address(0),
                block.number
            );
            betCount++;
        } else {
            totalBetsPlaced[msg.sender] += msg.value;
            placedBets[_betCount].better = msg.sender;
            placedBets[_betCount].amount = msg.value;
            whitelist.emitBetPlaced(msg.sender, msg.value, betCount, 2);

            pendingBets++;
            betCount++;
        }
    }

    //Function to cancel bets
    function cancelBet(uint256 _betId) external payable {
        require(msg.value == 0, "Don't send money to cancel a bet");
        require(
            placedBets[_betId].betState == BetState.PLACED,
            "Only placed bets can be cancelled"
        );
        require(
            placedBets[_betId].better == msg.sender,
            "Only the one who placed this bet can cancel it"
        );
        totalBetsPlaced[msg.sender] -= placedBets[_betId].amount;
        placedBets[_betId].betState = BetState.CANCELLED;
        (bool successUser, ) = msg.sender.call{
            value: placedBets[_betId].amount
        }("");
        require(successUser, "Transfer to user failed");
        whitelist.emitBetCancelled(_betId, msg.sender);
        pendingBets--;
    }

    //Function for players to call someone elses coinflip
    function callBet(uint256 _betId) external payable {
        require(
            placedBets[_betId].betState == BetState.PLACED,
            "Only placed bets can be called"
        );
        require(
            placedBets[_betId].amount == msg.value,
            "Send exact bet amount"
        );
        totalBetsPlaced[msg.sender] += msg.value;
        placedBets[_betId].caller = msg.sender;
        placedBets[_betId].betState = BetState.INITIALIZED;
        placedBets[_betId].blockNumberInitialized = block.number;
        noncePerBlock[block.number][betCountsPerBlock[block.number]] = _betId;
        betCountsPerBlock[block.number] += 1;
        pendingBets--;
        whitelist.emitBetCalled(
            msg.sender,
            block.number,
            _betId,
            placedBets[_betId].better
        );
    }

    function backupResolve(uint256 betId, bytes32 _resolutionSeed) external {
        require(msg.sender == owner, "Only owner can resolve bets");
        betStructure memory currentBet = placedBets[betId];
        require(currentBet.betState == BetState.INITIALIZED);
        currentBet.resolutionSeed = _resolutionSeed;
        currentBet.betState = BetState.RESOLVED;
        currentBet.betterWinner = resolveDuel(_resolutionSeed, betId);
        if (currentBet.betterWinner) {
            rewardBalances[currentBet.better] += currentBet.amount * 2;
        } else {
            if (currentBet.caller != address(0)) {
                rewardBalances[currentBet.caller] += currentBet.amount * 2;
            } else {
                bobBalance += currentBet.amount * 2;
            }
        }
        placedBets[betId] = currentBet;
        whitelist.emitBetResolved(
            _resolutionSeed,
            currentBet.betterWinner,
            betId,
            currentBet.better,
            currentBet.caller
        );
    }

    //Function to resolve Initialized bets
    function resolveBet(uint256 _blockNumber, bytes32 _resolutionSeed)
        external
    {
        require(msg.sender == owner, "Only owner can resolve bets");
        require(
            resolvedBlocks[_blockNumber] == false,
            "Block Number Already Resolved"
        );

        uint256 betCountOfBlock = betCountsPerBlock[_blockNumber];
        uint256 counter = 0;
        resolvedBlocks[_blockNumber] = true;
        while (counter < betCountOfBlock) {
            betStructure memory currentBet = placedBets[
                noncePerBlock[_blockNumber][counter]
            ];
            currentBet.resolutionSeed = _resolutionSeed;
            currentBet.betState = BetState.RESOLVED;
            currentBet.betterWinner = resolveDuel(
                _resolutionSeed,
                noncePerBlock[_blockNumber][counter]
            );
            if (currentBet.betterWinner) {
                rewardBalances[currentBet.better] += currentBet.amount * 2;
            } else {
                if (currentBet.caller != address(0)) {
                    rewardBalances[currentBet.caller] += currentBet.amount * 2;
                } else {
                    bobBalance += currentBet.amount * 2;
                }
            }
            placedBets[noncePerBlock[_blockNumber][counter]] = currentBet;
            whitelist.emitBetResolved(
                _resolutionSeed,
                currentBet.betterWinner,
                noncePerBlock[_blockNumber][counter],
                currentBet.better,
                currentBet.caller
            );
            counter++;
        }
    }

    //Internal function to find a winner of a dice duel
    function resolveDuel(bytes32 _resolutionSeed, uint256 nonce)
        internal
        view
        returns (bool)
    {
        uint256 localNonce = 0;
        while (true) {
            uint256 rollBetter1 = (uint256(
                keccak256(
                    abi.encodePacked(_resolutionSeed, nonce, localNonce + 1)
                )
            ) % 6) + 1;
            uint256 rollBetter2 = (uint256(
                keccak256(
                    abi.encodePacked(_resolutionSeed, nonce, localNonce + 2)
                )
            ) % 6) + 1;
            uint256 rollCaller1 = (uint256(
                keccak256(
                    abi.encodePacked(_resolutionSeed, nonce, localNonce + 3)
                )
            ) % 6) + 1;
            uint256 rollCaller2 = (uint256(
                keccak256(
                    abi.encodePacked(_resolutionSeed, nonce, localNonce + 4)
                )
            ) % 6) + 1;

            if (rollBetter1 + rollBetter2 == rollCaller1 + rollCaller2) {
                localNonce += 4;
            } else {
                return rollBetter1 + rollBetter2 > rollCaller1 + rollCaller2;
            }
        }
    }

    //Function for setting bet limits
    function setMinMax(uint256 _minBet, uint256 _maxBet) external {
        require(msg.sender == owner, "Only owner can set min bet");
        minBet = _minBet;
        maxBet = _maxBet;
    }

    //Function to call BOB
    function callBob(uint256 _betId) external {
        require(
            placedBets[_betId].better == msg.sender,
            "Only better can call Bob"
        );
        require(
            placedBets[_betId].betState == BetState.PLACED,
            "only placed bets can call bob"
        );
        require(
            placedBets[_betId].amount <= bobBalance,
            "Bob doesnt have enough to cover bet"
        );
        require(placedBets[_betId].amount <= maxBet, "Bet is above Max Bet");
        bobBalance -= placedBets[_betId].amount;
        placedBets[_betId].betState = BetState.INITIALIZED;
        placedBets[_betId].blockNumberInitialized = block.number;
        noncePerBlock[block.number][betCountsPerBlock[block.number]] = _betId;
        betCountsPerBlock[block.number] += 1;
        pendingBets--;
        whitelist.emitBetCalled(address(0), block.number, _betId, msg.sender);
    }

    //Function to claim winnings
    function withdrawWinnings() external payable {
        require(msg.value == 0, "Dont send bnb");
        require(
            rewardBalances[msg.sender] <= address(this).balance &&
                rewardBalances[msg.sender] > 0,
            "Smart Contract Doesnt have enough funds"
        );
        uint256 rewardsForPlayer = rewardBalances[msg.sender];
        rewardBalances[msg.sender] = 0;
        uint256 rewardPerCent = ((rewardsForPlayer -
            (rewardsForPlayer % 10000)) / 100);
        whitelist.recieve{value: rewardPerCent * 5}();
        (bool successUser, ) = msg.sender.call{value: (rewardPerCent * 95)}("");
        require(successUser, "Transfer to user failed");
        bool successMyth = mythContract.mintMythForRewards(
            rewardsForPlayer,
            msg.sender
        );
        require(successMyth, "Myth Minted");
        totalClaimedRewardsAddress[msg.sender] += rewardPerCent * 95;
    }

    function depoBob() external payable {
        require(msg.sender == owner, "Only the owner can load bob");
        bobBalance += msg.value;
    }
}

///////////////////////////     DICE DUEL
///////////////////////////     DICE DUEL
///////////////////////////     DICE DUEL

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////     Death Rolls
///////////////////////////     Death Rolls
///////////////////////////     Death Rolls

contract MythDeathRolls {
    address payable public owner;
    MythWhiteList public whitelist;
    Utilitytoken public mythContract;

    string public name = "Myth Death Rolls";

    uint256 public minBet = 3 * (10**16);
    uint256 public maxBet = 2 * (10**18);
    uint256 public bobBalance;

    mapping(address => uint256) public totalClaimedRewardsAddress;
    mapping(address => uint256) public totalBetsPlaced;
    mapping(address => uint256) public rewardBalances;
    mapping(uint256 => betStructure) public placedBets;
    mapping(uint256 => uint256) public betCountsPerBlock;
    mapping(uint256 => mapping(uint256 => uint256)) public noncePerBlock;
    mapping(uint256 => bool) public resolvedBlocks;

    uint256 public betCount;
    uint256 public pendingBets;

    enum BetState {
        PLACED,
        INITIALIZED,
        RESOLVED,
        CANCELLED
    }

    struct betStructure {
        address better;
        address caller;
        BetState betState;
        uint256 amount;
        uint256 blockNumberInitialized;
        bytes32 resolutionSeed;
        bool betterWinner;
    }

    constructor(address _whitelist, address _myth) {
        whitelist = MythWhiteList(_whitelist);
        mythContract = Utilitytoken(_myth);
        owner = payable(msg.sender);
        betCount = 0;
    }

    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        owner.transfer(address(this).balance);
        bobBalance = 0;
    }

    // Function for players to place bets
    function placeBet(bool _pvp) external payable {
        require(msg.value >= minBet, "Too little of bet");
        //If pvp is false then the user wants to VS the BOB (HOUSE)
        uint256 _betCount = betCount;
        if (!_pvp) {
            require(msg.value <= maxBet, "Too Big of a bet for Bob");
            require(
                msg.value <= bobBalance,
                "Bob does not have enough to cover bet"
            );
            bobBalance -= msg.value;
            placedBets[_betCount].better = msg.sender;
            placedBets[_betCount].betState = BetState.INITIALIZED;
            placedBets[_betCount].amount = msg.value;
            placedBets[_betCount].blockNumberInitialized = block.number;
            totalBetsPlaced[msg.sender] += msg.value;
            noncePerBlock[block.number][
                betCountsPerBlock[block.number]
            ] = _betCount;
            betCountsPerBlock[block.number] += 1;
            whitelist.emitBetPlacedCalled(
                msg.sender,
                msg.value,
                betCount,
                2,
                address(0),
                block.number
            );
            betCount++;
        } else {
            placedBets[_betCount].better = msg.sender;
            placedBets[_betCount].amount = msg.value;
            totalBetsPlaced[msg.sender] += msg.value;
            whitelist.emitBetPlaced(msg.sender, msg.value, _betCount, 2);
            pendingBets++;
            betCount++;
        }
    }

    //Function to cancel bets
    function cancelBet(uint256 _betId) external payable {
        require(msg.value == 0, "Don't send money to cancel a bet");
        require(
            placedBets[_betId].betState == BetState.PLACED,
            "Only placed bets can be cancelled"
        );
        require(
            placedBets[_betId].better == msg.sender,
            "Only the one who placed this bet can cancel it"
        );
        totalBetsPlaced[msg.sender] -= placedBets[_betId].amount;
        placedBets[_betId].betState = BetState.CANCELLED;
        (bool successUser, ) = msg.sender.call{
            value: placedBets[_betId].amount
        }("");
        require(successUser, "Transfer to user failed");
        whitelist.emitBetCancelled(_betId, msg.sender);
        pendingBets--;
    }

    //Function for players to call someone elses coinflip
    function callBet(uint256 _betId) external payable {
        require(
            placedBets[_betId].betState == BetState.PLACED,
            "Only placed bets can be called"
        );
        require(
            placedBets[_betId].amount == msg.value,
            "Send exact bet amount"
        );
        placedBets[_betId].caller = msg.sender;
        placedBets[_betId].betState = BetState.INITIALIZED;
        totalBetsPlaced[msg.sender] += msg.value;
        placedBets[_betId].blockNumberInitialized = block.number;
        noncePerBlock[block.number][betCountsPerBlock[block.number]] = _betId;
        betCountsPerBlock[block.number] += 1;
        pendingBets--;
        whitelist.emitBetCalled(
            msg.sender,
            block.number,
            _betId,
            placedBets[_betId].better
        );
    }

    function backupResolve(uint256 betId, bytes32 _resolutionSeed) external {
        require(msg.sender == owner, "Only owner can resolve bets");
        betStructure memory currentBet = placedBets[betId];
        require(currentBet.betState == BetState.INITIALIZED);
        currentBet.resolutionSeed = _resolutionSeed;
        currentBet.betState = BetState.RESOLVED;
        currentBet.betterWinner = resolveDuel(_resolutionSeed, betId);
        if (currentBet.betterWinner) {
            rewardBalances[currentBet.better] += currentBet.amount * 2;
        } else {
            if (currentBet.caller != address(0)) {
                rewardBalances[currentBet.caller] += currentBet.amount * 2;
            } else {
                bobBalance += currentBet.amount * 2;
            }
        }
        placedBets[betId] = currentBet;
        whitelist.emitBetResolved(
            _resolutionSeed,
            currentBet.betterWinner,
            betId,
            currentBet.better,
            currentBet.caller
        );
    }

    //Function to resolve Initialized bets
    function resolveBet(uint256 _blockNumber, bytes32 _resolutionSeed)
        external
    {
        require(msg.sender == owner, "Only owner can resolve bets");
        require(
            resolvedBlocks[_blockNumber] == false,
            "Block Number Already Resolved"
        );

        uint256 betCountOfBlock = betCountsPerBlock[_blockNumber];
        uint256 counter = 0;
        resolvedBlocks[_blockNumber] = true;
        while (counter < betCountOfBlock) {
            betStructure memory currentBet = placedBets[
                noncePerBlock[_blockNumber][counter]
            ];
            currentBet.resolutionSeed = _resolutionSeed;
            currentBet.betState = BetState.RESOLVED;
            currentBet.betterWinner = resolveDuel(
                _resolutionSeed,
                noncePerBlock[_blockNumber][counter]
            );
            if (currentBet.betterWinner) {
                rewardBalances[currentBet.better] += currentBet.amount * 2;
            } else {
                if (currentBet.caller != address(0)) {
                    rewardBalances[currentBet.caller] += currentBet.amount * 2;
                } else {
                    bobBalance += currentBet.amount * 2;
                }
            }
            placedBets[noncePerBlock[_blockNumber][counter]] = currentBet;
            whitelist.emitBetResolved(
                _resolutionSeed,
                currentBet.betterWinner,
                noncePerBlock[_blockNumber][counter],
                currentBet.better,
                currentBet.caller
            );
            counter++;
        }
    }

    //Internal function to find a winner of a dice duel
    function resolveDuel(bytes32 _resolutionSeed, uint256 nonce)
        internal
        view
        returns (bool)
    {
        uint256 localNonce = 0;
        uint256 currentNumber = 1000;
        while (true) {
            uint256 roll = uint256(
                keccak256(abi.encodePacked(_resolutionSeed, nonce, localNonce))
            ) % currentNumber;
            localNonce++;
            if (roll == 0) {
                break;
            } else {
                currentNumber = roll;
            }
        }
        return localNonce % 2 == 0;
    }

    //Function for setting bet limits
    function setMinMax(uint256 _minBet, uint256 _maxBet) external {
        require(msg.sender == owner, "Only owner can set min bet");
        minBet = _minBet;
        maxBet = _maxBet;
    }

    //Function to call BOB
    function callBob(uint256 _betId) external {
        require(
            placedBets[_betId].better == msg.sender,
            "Only better can call Bob"
        );
        require(
            placedBets[_betId].betState == BetState.PLACED,
            "only placed bets can call bob"
        );
        require(
            placedBets[_betId].amount <= bobBalance,
            "Bob doesnt have enough to cover bet"
        );
        require(placedBets[_betId].amount <= maxBet, "Bet is above Max Bet");
        bobBalance -= placedBets[_betId].amount;
        placedBets[_betId].betState = BetState.INITIALIZED;
        placedBets[_betId].blockNumberInitialized = block.number;
        noncePerBlock[block.number][betCountsPerBlock[block.number]] = _betId;
        betCountsPerBlock[block.number] += 1;
        pendingBets--;
        whitelist.emitBetCalled(address(0), block.number, _betId, msg.sender);
    }

    //Function to claim winnings
    function withdrawWinnings() external payable {
        require(msg.value == 0, "Dont send bnb");
        require(
            rewardBalances[msg.sender] <= address(this).balance,
            "Smart Contract Doesnt have enough funds"
        );
        uint256 rewardsForPlayer = rewardBalances[msg.sender];
        rewardBalances[msg.sender] = 0;
        uint256 rewardPerCent = ((rewardsForPlayer -
            (rewardsForPlayer % 10000)) / 100);
        whitelist.recieve{value: rewardPerCent * 5}();
        (bool successUser, ) = msg.sender.call{value: (rewardPerCent * 95)}("");
        require(successUser, "Transfer to user failed");
        bool successMyth = mythContract.mintMythForRewards(
            rewardsForPlayer,
            msg.sender
        );
        require(successMyth, "Myth Minted");
        totalClaimedRewardsAddress[msg.sender] += rewardPerCent * 95;
    }

    function depoBob() external payable {
        require(msg.sender == owner, "Only the owner can load bob");
        bobBalance += msg.value;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * BEP20 standard interface.
 */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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