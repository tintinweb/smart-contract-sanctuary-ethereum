// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.7;

/*$$$$$$$ /$$                            /$$$$$$  /$$   /$$              
|__  $$__/| $$                           /$$__  $$|__/  | $$              
   | $$   | $$$$$$$  /$$   /$$  /$$$$$$ | $$  \__/ /$$ /$$$$$$   /$$   /$$
   | $$   | $$__  $$| $$  | $$ /$$__  $$| $$      | $$|_  $$_/  | $$  | $$
   | $$   | $$  \ $$| $$  | $$| $$  \ $$| $$      | $$  | $$    | $$  | $$
   | $$   | $$  | $$| $$  | $$| $$  | $$| $$    $$| $$  | $$ /$$| $$  | $$
   | $$   | $$  | $$|  $$$$$$/|  $$$$$$$|  $$$$$$/| $$  |  $$$$/|  $$$$$$$
   |__/   |__/  |__/ \______/  \____  $$ \______/ |__/   \___/   \____  $$
                               /$$  \ $$                         /$$  | $$
                              |  $$$$$$/                        |  $$$$$$/
                               \______/                          \______*/

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

//INTERFACE: NFT contract
interface IThugCityNFT {
    function ownerOf(uint256 id) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
    function isCop(uint256 id) external view returns (bool);
}

//INTERFACE: $BILLS token contract
interface IBills {
    function mint(address account, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external;
    function balanceOf(address user) external returns (uint256);
    function transfer(address to, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}

//INTERFACE: Assets contract
interface IAssets {
    function addGun(uint256 tokenId, address addr, uint256 amount) external;
    function addMedallion(address addr, uint256 amount) external;
    function addReward(address addr, uint256 location, uint256 reward) external;
    function getPoints(address addr) external view returns (uint256);
    function getGuns(uint256 tokenId) external view returns (uint256);
}

contract City is Ownable, IERC721Receiver, ReentrancyGuard {

    //EVENTS: Emitted upon completion of action
    event Deposit(address from, uint256 amount);
    event Withdraw(address _addr, uint256 owed);
    event CrimeCommitted(uint256 tokenId, uint256 location, uint256 reward, uint256[] locationCops);
    event GunPurchased(uint256 tokenId, uint256 amount);
    event Staked(uint256[] tokenIds);
    event CopMoved(uint256 tokenId, uint256 location);

    bool private _paused = true;

    //DECLARE: Random variables
    mapping(uint256 => address) private _randomSource;
    uint256 private _randomIndex = 0;
    uint256 private _randomCalls = 0;

    //DECLARE: Store stake values
    struct Stake {
        uint256 tokenId;
        uint256 value;
        uint256 spent;
        uint256 location;
        uint256 locationPoints;
    }

    //**HARDCODE**: Initialize citizen
    IThugCityNFT public citizen;

    //**HARDCODE**: Initialize bills
    IBills public bills;

    //**HARDCODE**: Initialize assets
    IAssets public assets;

    //DECLARE: Map cops to stake and location
    mapping(uint256 => uint256) public copCollection;
    mapping(address => Stake[]) public copStake;

    // Mappings index cop position in stakedCops array
    mapping(uint256 => uint256) public copBankCollection; //Stake location 1
    mapping(uint256 => uint256) public copCasinoCollection; //Stake location 2
    mapping(uint256 => uint256) public copPrisonCollection; //Stake location 3
    mapping(uint256 => uint256) public copDealershipCollection; //Stake location 4

    mapping(uint256 => uint256) private locationPointTracker;

    // Arrays holding all cops staked at specific locations
    uint256[] public bankStakedCops; //Stake location 1
    uint256[] public casinoStakedCops; //Stake location 2
    uint256[] public prisonStakedCops; //Stake location 3
    uint256[] public dealershipStakedCops; //Stake location 4

    //DECLARE: Map thugs to stake
    mapping(uint256 => uint256) public thugCollection;
    mapping(address => Stake[]) public thugStake;

    mapping(uint256 => address) public ownerOfStaked;
    mapping(address => uint256) public deposited;

    //DECLARE: Total total thugs and cops staked
    uint256 public totalCopsStaked;
    uint256 public totalThugsStaked;

    //DECLARE: Daily rates, crime prices and maximums
    uint256 private immutable DAILY_BILLS_RATE = 1000 ether;
    uint256 private immutable DAILY_COP_BILLS_RATE = 1200 ether;
    uint256[] private prices = [1000 ether, 2000 ether, 4000 ether, 8000 ether];
    uint256 private gunCost = 1000 ether;

    uint256 public chance = 101;
    //DECLARE: Emergency rescue to allow unstaking without $BILLS
    bool public rescueEnabled = false;
    
    uint256 public lastBlockTimestamp;

    uint256 public newestTokenID;

    //CONSTRUCTOR: Sets addresses for other contracts
    constructor(address _citizen, address _bills, address _assets, uint256 newest) {
        setContracts(_citizen, _bills, _assets);
        newestTokenID = newest;
        _randomSource[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        _randomSource[1] = 0x64192819Ac13Ef72bF6b5AE239AC672B43a9AF08;
        _randomSource[2] = 0xC098B2a3Aa256D2140208C3de6543aAEf5cd3A94;
        _randomSource[3] = 0x28C6c06298d514Db089934071355E5743bf21d60;
        _randomSource[4] = 0x6262998Ced04146fA42253a5C0AF90CA02dfd2A3;
        _randomSource[5] = 0x267be1C1D684F78cb4F6a176C4911b741E4Ffdc0;
        _randomSource[6] = 0x2FAF487A4414Fe77e2327F0bf4AE2a264a776AD2;
    }

    // Starts game allowing users to stake NFTs and sets season 1 end time
    function startGame() external onlyOwner {
        lastBlockTimestamp = block.timestamp + 20 weeks;
        _paused = false;
    }

    //STAKING: Stakes cops and thugs
    function addManyToCity(address account, uint256[] calldata tokenIds) external nonReentrant whenNotPaused {
        require(tx.origin == msg.sender);
        uint256 currentBlock = block.timestamp;
        
        if(block.timestamp > lastBlockTimestamp){
            currentBlock = lastBlockTimestamp;
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] <= newestTokenID);
            require(citizen.ownerOf(tokenIds[i]) == msg.sender);
            citizen.transferFrom(msg.sender, address(this), tokenIds[i]);
            if (citizen.isCop(tokenIds[i])) {
                copCollection[tokenIds[i]] = copStake[account].length;
                copStake[account].push(Stake({
                        tokenId: tokenIds[i],
                        value: currentBlock,
                        spent: 0,
                        location: 0,
                        locationPoints: 0
                        })
                );
                ownerOfStaked[tokenIds[i]] = account;
                totalCopsStaked++;
            } else {
                thugCollection[tokenIds[i]] = thugStake[account].length;
                thugStake[account].push(Stake({
                        tokenId: tokenIds[i],
                        value: currentBlock,
                        spent: 0,
                        location: 0,
                        locationPoints: 0
                        })
                );
                ownerOfStaked[tokenIds[i]] = account;
                totalThugsStaked++;
            }
        }
        emit Staked(tokenIds);
    }

    //COP STAKING: Moves cop to specified location
    function stakeCopAtLocation(address account, uint256 tokenId, uint256 stakeLocation) external whenNotPaused {
        require(account == msg.sender);
        require(citizen.isCop(tokenId));
        require(assets.getGuns(tokenId) >= stakeLocation, "Not enough guns!");
        Stake storage stake = copStake[msg.sender][copCollection[tokenId]];
        require(ownerOfStaked[tokenId] == msg.sender, "Must be owner of NFT!");
        require(stake.location != stakeLocation, "Cannot move to same location!");
        if(stake.location != 0){
            removeCopLocationStake(tokenId, stake.location);
        }
        stake.location = stakeLocation;
        stake.locationPoints = locationPointTracker[stakeLocation];
        if(stakeLocation == 4){
            copBankCollection[tokenId] = bankStakedCops.length;
            bankStakedCops.push(tokenId);
        }else if(stakeLocation == 3){
            copCasinoCollection[tokenId] = casinoStakedCops.length;
            casinoStakedCops.push(tokenId);
        }else if(stakeLocation == 2){
            copPrisonCollection[tokenId] = prisonStakedCops.length;
            prisonStakedCops.push(tokenId);
        }else if(stakeLocation == 1){
            copDealershipCollection[tokenId] = dealershipStakedCops.length;
            dealershipStakedCops.push(tokenId);
        }
        emit CopMoved(tokenId, stakeLocation);
    }

    //WITHDRAWING FUNDS: Withdraws all funds of address
    function withdrawAll(address _addr) public whenNotPaused {
        require(msg.sender == _addr);
        Stake[] storage thugs = thugStake[_addr];
        Stake[] storage cops = copStake[_addr];
        uint256 owed = deposited[_addr];
        uint256 currentBlock = block.timestamp;
        if(block.timestamp > lastBlockTimestamp){
            currentBlock = lastBlockTimestamp;
        }
        for(uint256 i = 0; i < thugs.length; i++){
            owed += ((currentBlock - thugs[i].value) * DAILY_BILLS_RATE) / 1 days - thugs[i].spent;
            thugs[i].value = currentBlock;
            thugs[i].spent = 0;
        }
        for(uint256 i = 0; i < cops.length; i++){
            owed += ((currentBlock - cops[i].value) * DAILY_COP_BILLS_RATE) / 1 days - cops[i].spent;
            cops[i].value = currentBlock;
            cops[i].spent = 0;
        }
        deposited[_addr] = 0;
        bills.mint(_addr, owed);
        emit Withdraw(_addr, owed);
    }

    //DEPOSITING FUNDS: Allow users to deposit only up to users available balance
    function depositBills(address _addr, uint256 amount) external whenNotPaused {
        require(tx.origin == msg.sender && msg.sender == _addr);
        require(amount > 0);
        require(bills.balanceOf(msg.sender) >= amount);
        bills.burn(msg.sender, amount);
        deposited[_addr] += amount;
        emit Deposit(msg.sender, amount);
    }

    //UNSTAKING: Unstake and claim from thugs and cops
    function unstakeManyFromCity(uint256[] calldata tokenIds, bool withdrawAllFunds) external nonReentrant whenNotPaused {
        uint256 currentBlock = block.timestamp;
        uint256 earned = 0;
        if(block.timestamp > lastBlockTimestamp){
            currentBlock = lastBlockTimestamp;
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOfStaked[tokenId] == msg.sender);
            if (citizen.isCop(tokenId)) {
                earned += ((currentBlock - copStake[msg.sender][copCollection[tokenId]].value) * DAILY_COP_BILLS_RATE) / 1 days - copStake[msg.sender][copCollection[tokenId]].spent;
                if(copStake[msg.sender][copCollection[tokenId]].location != 0) {
                    removeCopLocationStake(tokenId, copStake[msg.sender][copCollection[tokenId]].location);
                }
                Stake memory lastStake = copStake[msg.sender][copStake[msg.sender].length - 1];
                copStake[msg.sender][copCollection[tokenId]] = lastStake;
                copCollection[lastStake.tokenId] = copCollection[tokenId];
                copStake[msg.sender].pop();
                totalCopsStaked--;
                delete copCollection[tokenId];
                delete ownerOfStaked[tokenId];
                citizen.safeTransferFrom(address(this), msg.sender, tokenId, "");
            } else { // UNSTAKE THUG
                earned += ((currentBlock - thugStake[msg.sender][thugCollection[tokenId]].value) * DAILY_BILLS_RATE) / 1 days - thugStake[msg.sender][thugCollection[tokenId]].spent;
                Stake memory lastStake = thugStake[msg.sender][thugStake[msg.sender].length - 1];
                thugStake[msg.sender][thugCollection[tokenId]] = lastStake;
                thugCollection[lastStake.tokenId] = thugCollection[tokenId];
                thugStake[msg.sender].pop();
                totalThugsStaked--;
                delete thugCollection[tokenId];
                delete ownerOfStaked[tokenId];
                citizen.safeTransferFrom(address(this), msg.sender, tokenId, "");
            }
        }
        deposited[msg.sender] += earned;
        if(withdrawAllFunds) withdrawAll(msg.sender);
    }

    //CRIMES: TokenId commits crime at location
    function crime(uint256 tokenId, uint256 location) external whenNotPaused  {
        require(!citizen.isCop(tokenId));
        require(assets.getGuns(tokenId) >= location);
        require(spend(msg.sender, prices[location-1]) == 0);
        uint256 reward = 0;
        uint256 rand = getRandomNumber(tokenId, 100);
        updateRandomIndex();
        uint256 chances = chance;
        if(chances == 101) chances = getResult(location);
        if(rand < chances){
            if(rand < 51) {
                reward = 1;
            }else{
                reward = 2;
            }
            assets.addReward(msg.sender, location, reward);
        }else {
            locationPointTracker[location] += location;
        }

        if(location == 4){
            emit CrimeCommitted(tokenId, 4, reward, bankStakedCops);
        }else if(location == 3){
            emit CrimeCommitted(tokenId, 3, reward, casinoStakedCops);
        }else if(location == 2){
            emit CrimeCommitted(tokenId, 2, reward, prisonStakedCops);
        }else if(location == 1){
            emit CrimeCommitted(tokenId, 1, reward, dealershipStakedCops);
        }
    }

    //CHANCE: Determines chance of success at specified location
    function getResult(uint256 location) public virtual view returns (uint256) {
        uint256 locationStaked = 0;
        uint256 totalCopsPlaying = dealershipStakedCops.length + prisonStakedCops.length + casinoStakedCops.length + bankStakedCops.length;
        if(location == 1){
            locationStaked = dealershipStakedCops.length;
        }else if(location == 2){
            locationStaked = prisonStakedCops.length;
        }else if(location == 3){
            locationStaked = casinoStakedCops.length;
        }else if(location == 4){
            locationStaked = bankStakedCops.length;
        }
        if(locationStaked == 0) return 99;
        uint256 ratio = ((locationStaked*100)/(totalCopsPlaying));
        uint256 chances;
        if(ratio > 24) chances = (12*ratio)/10 - 25;
        else chances = (16*ratio)/100 + 1;
        return 100-chances;
    }


    // ROBBING: User buys gun at gun store
    function buyGun(uint256 tokenId, uint256 amount) public whenNotPaused {
        uint256 spending = gunCost*amount;
        require(ownerOfStaked[tokenId] == msg.sender, "Not owner");
        require(assets.getGuns(tokenId) + amount < 5, "Too many guns");
        require(spend(msg.sender, spending) == 0, "Not enough loot");
        assets.addGun(tokenId, msg.sender, amount);
        emit GunPurchased(tokenId, amount);
    }


    // SPENDING: User spends $BILLS
    function spend(address _addr, uint256 amount) internal nonReentrant returns (uint256 spending) {
        Stake[] storage thugs = thugStake[_addr];
        Stake[] storage cops = copStake[_addr];
        spending = amount;
        uint256 currentBlock = block.timestamp;
      
        if(block.timestamp > lastBlockTimestamp){
            currentBlock = lastBlockTimestamp;
        }
        
        if(deposited[_addr] >= amount){
            deposited[_addr] -= spending;
            spending = 0;
        }else{
            
            if(deposited[_addr] > 0){
                spending -= deposited[_addr];
                deposited[_addr] = 0;
            }
            
            for(uint256 i = 0; i < thugs.length; i++){

                uint256 owed = ((currentBlock - thugs[i].value) * DAILY_BILLS_RATE) / 1 days - thugs[i].spent; // 
                if(owed >= spending){
                    thugs[i].spent += spending;
                    spending = 0;
                    break;
                }else{
                    spending -= owed;
                    if(thugs[i].spent > 0) thugs[i].spent = 0;
                    thugs[i].value = currentBlock;
                }
            }
            if(spending != 0){
                for(uint256 i = 0; i < cops.length; i++){
                    uint256 owed = ((currentBlock - cops[i].value) * DAILY_COP_BILLS_RATE) / 1 days - cops[i].spent;
                    if(owed >= spending){
                        cops[i].spent += spending;
                        spending = 0;
                        break;
                    }else{
                        spending -= owed;
                        if(cops[i].spent > 0) cops[i].spent = 0;
                        cops[i].value = currentBlock;
                    }
                }
            }
        }
    }

    //MISC: Removes cop location stake when moved or unstaked
    function removeCopLocationStake(uint256 tokenId, uint256 _location) internal {
        assets.addMedallion(msg.sender, locationPointTracker[_location] - copStake[ownerOfStaked[tokenId]][copCollection[tokenId]].locationPoints);
        copStake[ownerOfStaked[tokenId]][copCollection[tokenId]].locationPoints = 0;
        if (_location == 4) {
            uint256 lastStake = bankStakedCops[bankStakedCops.length-1];
            bankStakedCops[copBankCollection[tokenId]] = lastStake;
            copBankCollection[lastStake] = copBankCollection[tokenId];
            bankStakedCops.pop();
            delete copBankCollection[tokenId];
        } else if (_location == 3) {
            uint256 lastStake = casinoStakedCops[casinoStakedCops.length-1];
            casinoStakedCops[copCasinoCollection[tokenId]] = lastStake;
            copCasinoCollection[lastStake] = copCasinoCollection[tokenId];
            casinoStakedCops.pop();
            delete copCasinoCollection[tokenId];
        } else if (_location == 2) {
            uint256 lastStake = prisonStakedCops[prisonStakedCops.length-1];
            prisonStakedCops[copPrisonCollection[tokenId]] = lastStake;
            copPrisonCollection[lastStake] = copPrisonCollection[tokenId];
            prisonStakedCops.pop();
            delete copPrisonCollection[tokenId];
        } else if (_location == 1) {
            uint256 lastStake = dealershipStakedCops[dealershipStakedCops.length-1];
            dealershipStakedCops[copDealershipCollection[tokenId]] = lastStake;
            copDealershipCollection[lastStake] = copDealershipCollection[tokenId];
            dealershipStakedCops.pop();
            delete copDealershipCollection[tokenId];
        }
    }

    //MISC: Emergency unstake tokens
    function rescue(uint256[] calldata tokenIds) external nonReentrant {
        require(rescueEnabled);
        uint256 tokenId;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            require(ownerOfStaked[tokenId] == msg.sender);
            if (citizen.isCop(tokenId)) {
                Stake memory lastStake = copStake[msg.sender][copStake[msg.sender].length - 1];
                copStake[msg.sender][copCollection[tokenId]] = lastStake;
                copCollection[lastStake.tokenId] = copCollection[tokenId];
                copStake[msg.sender].pop();

                totalCopsStaked--;
                delete copCollection[tokenId];
                delete ownerOfStaked[tokenId];
                citizen.safeTransferFrom(address(this), msg.sender, tokenId,"");
            } else {
                Stake memory lastStake = thugStake[msg.sender][thugStake[msg.sender].length - 1];
                thugStake[msg.sender][thugCollection[tokenId]] = lastStake;
                thugCollection[lastStake.tokenId] = thugCollection[tokenId];
                thugStake[msg.sender].pop();

                totalThugsStaked--;
                delete thugCollection[tokenId];
                delete ownerOfStaked[tokenId];
                citizen.safeTransferFrom(address(this),msg.sender,tokenId,"");
            }
        }
    }

    // Sets chance (if not using Cop % based model)
    function setChance(uint256 _chance) external {
        chance = _chance;
    }


    // Returns balance of users Thugs and Cops + deposited funds
    function getUserBalance(address _addr) external view virtual returns (uint256 balance) {
        balance = 0;
        uint256 currentBlock = block.timestamp;
        if(block.timestamp > lastBlockTimestamp){
            currentBlock = lastBlockTimestamp;
        }
        for(uint256 i = 0; i < thugStake[_addr].length; i++){
            balance += ((currentBlock - thugStake[_addr][i].value) * DAILY_BILLS_RATE) / 1 days - thugStake[_addr][i].spent;
        }
        for(uint256 i = 0; i < copStake[_addr].length; i++){
            balance += ((currentBlock - copStake[_addr][i].value) * DAILY_COP_BILLS_RATE) / 1 days - copStake[_addr][i].spent;
        }
        balance += deposited[_addr];
    }

    // Returns points of user
    function getUserPoints(address _addr) external view virtual returns (uint256 points) {
        points += getAllUnclaimedMedallions(_addr);
        points += assets.getPoints(_addr);
    }

    // Returns unclaimed medallions of specific tokenId
    function getUnclaimedMedallions(uint256 tokenId) external view virtual returns (uint256) {
        return locationPointTracker[copStake[ownerOfStaked[tokenId]][copCollection[tokenId]].location] - copStake[ownerOfStaked[tokenId]][copCollection[tokenId]].locationPoints;
    }

    // Returns all user unclaimed medallions
    function getAllUnclaimedMedallions(address addr) public view virtual returns (uint256 medallions) {
        for(uint i = 0; i < copStake[addr].length; i++){
            medallions += locationPointTracker[copStake[addr][i].location] - copStake[addr][i].locationPoints;
        }
    }

    // Returns array of Thug tokenIds staked by user
    function getUserStakedThugs(address _addr) external view virtual returns(uint256[] memory){
        uint256[] memory tokenIds = new uint256[](thugStake[_addr].length);
        for(uint256 i = 0; i < thugStake[_addr].length; i++){
            tokenIds[i] = thugStake[_addr][i].tokenId;
        }
        return tokenIds;
    }

    // Returns array of Cop tokenIds staked by user
    function getUserStakedCops(address _addr) external view virtual returns(uint256[] memory){
        uint256[] memory tokenIds = new uint256[](copStake[_addr].length);
        for(uint256 i = 0; i < copStake[_addr].length; i++){
            tokenIds[i] = copStake[_addr][i].tokenId;
        }
        return tokenIds;
    }

    // Returns array of users staked cops at location
    function getUserLocationStakedCops(address _addr, uint256 _location) public view virtual returns(uint256[] memory){
        uint256[] memory tokenIds = new uint256[](copStake[_addr].length);
        uint256 count = 0;
        for(uint256 i = 0; i < copStake[_addr].length; i++){
            if(copStake[_addr][i].location == _location){
                tokenIds[count] = copStake[_addr][i].tokenId;
                count++;
            }
        }
        return tokenIds;
    }

    //Returns all cops staked at location
    function getLocationStakedCops(uint256 _location) public view virtual returns (uint256[] memory tokenIds) {
        if(_location == 1){
            tokenIds = dealershipStakedCops;
        }else if(_location == 2){
            tokenIds = prisonStakedCops;
        }else if(_location == 3){
            tokenIds = casinoStakedCops;
        }else if(_location == 4){
            tokenIds = bankStakedCops;
        }
    }

    // Returns cop location
    function getCopLocation(uint256 tokenId) public view virtual returns(uint256){
        return copStake[ownerOfStaked[tokenId]][copCollection[tokenId]].location;
    }

    // SETTERS //

    //OWNER: Set prices of locations
    function setLocationPrices(uint256 _bank, uint256 _casino, uint256 _prison, uint256 _dealership, uint256 _gunCost) external onlyOwner {
        prices[3] = _bank;
        prices[2] = _casino;
        prices[1] = _prison;
        prices[0] = _dealership;
        gunCost = _gunCost;
    }

    //OWNER: Enabling rescue command
    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }

    //OWNER: Sets timestamp of game end
    function setLastTimestamp(uint256 _timestamp) external onlyOwner {
        lastBlockTimestamp = _timestamp;
    }

    // Sets newest tokenid that can be staked (cops have been mapped up to this tokenId)
    function setNewestTokenId(uint256 _tokenId) external onlyOwner {
        newestTokenID = _tokenId;
    }

    //OWNER: Set contract addresses
    function setContracts(address _citizen, address _bills, address _assets) public onlyOwner {
        citizen = IThugCityNFT(_citizen);
        bills = IBills(_bills);
        assets = IAssets(_assets);
    }

    //OWNER: Enable pausing of game
    function setPaused(bool _state) external onlyOwner {
        _paused = _state;
    }

    //MISC: View if game is paused
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused());
        _;
    }


    //MISC: Get random number
    function getRandomNumber(uint256 _seed, uint256 _limit) internal view returns (uint256) {
        uint256 extra = 0;
        for (uint256 i = 0; i < 7; i++) {
            extra += _randomSource[_randomIndex].balance;
        }

        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    _seed,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender,
                    extra,
                    _randomCalls,
                    _randomIndex
                )
            )
        );

        return uint256(random % _limit);
    }

    //OWNER: Change source of random numbers
    function changeRandomSource(uint256 _id, address _address) external onlyOwner {
        _randomSource[_id] = _address;
    }

    //MISC: Update random index
    function updateRandomIndex() internal {
        _randomIndex++;
        _randomCalls++;
        if (_randomIndex > 4) _randomIndex = 0;
    }

    //OWNER: Shuffle seeds of random numbers
    function shuffleSeeds(uint256 _seed, uint256 _max) external onlyOwner {
        uint256 shuffleCount = getRandomNumber(_seed, _max);
        _randomIndex = uint256(shuffleCount);
        for (uint256 i = 0; i < shuffleCount; i++) {
            updateRandomIndex();
        }
    }

    //MISC: ERC721 needed command
    function onERC721Received(address, address from, uint256, bytes calldata) external pure override returns (bytes4) {
        require(from == address(0x0));
        return IERC721Receiver.onERC721Received.selector;
    }
}