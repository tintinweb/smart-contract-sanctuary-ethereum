// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

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
    function addGun(uint256 tokenId, uint256 amount) external;
    function addMedallion(uint256 tokenId, uint256 amount) external;
    function addReward(uint256 tokenId, uint256 location, uint256 reward) external;
    function getPoints(uint256 tokenId) external view returns (uint256);
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
    uint256 public chance = 90;

    //DECLARE: Random variables
    mapping(uint256 => address) private _randomSource;
    uint256 private _randomIndex = 0;
    uint256 private _randomCalls = 0;

    //DECLARE: Store stake values
    struct Stake {
        uint256 tokenId;
        uint256 value;
        address owner;
        uint256 spent;
        uint256 location;
        uint256 locationPoints;
        uint256 currentEarningRate;
    }

    //**HARDCODE**: Initialize citizen CHANGE TO PARAM FOR MAINNET
    IThugCityNFT public citizen = IThugCityNFT(0xBF37Ef466E7E7CC06328dE52A76a82Aa33451F9d);

    //**HARDCODE**: Initialize bills CHANGE TO PARAM FOR MAINNET
    IBills public bills = IBills(0x0adFfF6fe7059a04C676e2A462Fc6e623daE4e75);

    //**HARDCODE**: Initialize assets CHANGE TO PARAM FOR MAINNET
    IAssets public assets = IAssets(0x938ba67690Dafd120A450F169B39Cc0647e56cfB);

    //DECLARE: Map cops to stake and location
    mapping(uint256 => uint256) public copCollection;
    mapping(address => Stake[]) public copStake;

    // Mappings index cop position in stakedCops array
    mapping(uint256 => uint256) public copBankCollection; //Stake location 1
    mapping(uint256 => uint256) public copCasinoCollection; //Stake location 2
    mapping(uint256 => uint256) public copPrisonCollection; //Stake location 3
    mapping(uint256 => uint256) public copDealershipCollection; //Stake location 4

    mapping(uint256 => uint256) public locationPointTracker;

    // Arrays holding all cops staked at specific locations
    uint256[] public bankStakedCops; //Stake location 1
    uint256[] public casinoStakedCops; //Stake location 2
    uint256[] public prisonStakedCops; //Stake location 3
    uint256[] public dealershipStakedCops; //Stake location 4

    //DECLARE: Map thugs to stake
    mapping(uint256 => uint256) public thugCollection;
    mapping(address => Stake[]) public thugStake;

    // Mappings to check if staked
    mapping(uint256 => bool) private staked;
    mapping(uint256 => address) public ownerOfStaked;
    mapping(address => uint256) public deposited;

    //DECLARE: Total total thugs and cops staked
    uint256 public totalCopsStaked;
    uint256 public totalThugsStaked;

    //DECLARE: Daily rates, crime prices and maximums
    uint256 private DAILY_BILLS_RATE = 10000 ether;
    uint256 private DAILY_COP_BILLS_RATE = 12000 ether;
    uint256[] private prices = [2000 ether, 3000 ether, 4000 ether, 5000 ether];
    uint256 private gunCost = 1000 ether;

    //DECLARE: Emergency rescue to allow unstaking without $BILLS
    bool public rescueEnabled = false;
    mapping(uint256 => uint256) public rescueBalances;
    
    uint256 public lastBlockTimestamp;



    //CONSTRUCTOR: Sets addresses for other contracts
    constructor(/*address _citizen, address _bills, address _assets*/) {
        //setContracts(_citizen, _bills, _assets);
        _randomSource[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        _randomSource[1] = 0x3cD751E6b0078Be393132286c442345e5DC49699;
        _randomSource[2] = 0xC098B2a3Aa256D2140208C3de6543aAEf5cd3A94;
        _randomSource[3] = 0x28C6c06298d514Db089934071355E5743bf21d60;
        _randomSource[4] = 0x267be1C1D684F78cb4F6a176C4911b741E4Ffdc0;
    }

    function startGame() external onlyOwner {
        lastBlockTimestamp = block.timestamp + 12 weeks;
        _paused = false;
    }

    //STAKING: Adds cops and/or thugs to thugcity (cops added to cop station, location = 0
    function addManyToCity(address account, uint256[] calldata tokenIds) external nonReentrant whenNotPaused {
        require(tx.origin == msg.sender);
        uint256 currentBlock = block.timestamp;
        if(block.timestamp > lastBlockTimestamp){
            currentBlock = lastBlockTimestamp;
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(citizen.ownerOf(tokenIds[i]) == msg.sender); // checking with NFT contract for ownership
            citizen.transferFrom(msg.sender, address(this), tokenIds[i]);
            if (citizen.isCop(tokenIds[i])) {
                copCollection[tokenIds[i]] = copStake[account].length;
                copStake[account].push(Stake({
                        owner: account,
                        tokenId: tokenIds[i],
                        value: currentBlock,
                        spent: 0,
                        location: 0,
                        locationPoints: 0,
                        currentEarningRate: DAILY_COP_BILLS_RATE
                        })
                );
                ownerOfStaked[tokenIds[i]] = account;
                totalCopsStaked++;
            } else {
                thugCollection[tokenIds[i]] = thugStake[account].length;
                thugStake[account].push(Stake({
                        owner: account,
                        tokenId: tokenIds[i],
                        value: currentBlock,
                        spent: 0,
                        location: 0,
                        locationPoints: 0,
                        currentEarningRate: DAILY_BILLS_RATE
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
        require(stake.owner == msg.sender, "Must be owner of NFT!");
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

    //MISC: Allow users to withdraw all available bills from certain NFT
    function withdrawSome(address _addr, uint256 amount) public nonReentrant whenNotPaused {
        require(msg.sender == _addr);
        Stake[] storage thugs = thugStake[_addr];
        Stake[] storage cops = copStake[_addr];
        require(amount > 0);
        uint256 spending = amount;
        uint256 currentBlock = block.timestamp;
        if(block.timestamp > lastBlockTimestamp){
            currentBlock = lastBlockTimestamp;
        }
        require(getUserBalance(_addr) >= amount);
        if(deposited[_addr] >= amount){
            deposited[_addr] -= spending;
            spending = 0;
        }else{
            spending -= deposited[_addr];
            deposited[_addr] = 0;
            for(uint256 i = 0; i < thugs.length; i++){
                uint256 owed = ((currentBlock - thugs[i].value) * thugs[i].currentEarningRate) / 1 days - thugs[i].spent;
                if(owed >= spending){
                    thugs[i].spent += spending;
                    spending = 0;
                }else{
                    spending -= owed;
                    thugs[i].spent = 0;
                    thugs[i].value = currentBlock;
                }
                if(spending == 0) break;
            }
            if(spending != 0){
                for(uint256 i = 0; i < cops.length; i++){
                    uint256 owed = ((currentBlock - cops[i].value) * cops[i].currentEarningRate) / 1 days - cops[i].spent;
                    if(owed >= spending){
                        cops[i].spent += spending;
                        spending = 0;
                    }else{
                        spending -= owed;
                        cops[i].spent = 0;
                        cops[i].value = currentBlock;
                    }
                    if(spending == 0) break;
                }
            }
        }
        if(spending == 0){
            bills.mint(_addr, amount);
        }
        emit Withdraw(_addr, amount); // emits output of withdrawal
    }

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
            owed += ((currentBlock - thugs[i].value) * thugs[i].currentEarningRate) / 1 days - thugs[i].spent;
            thugs[i].value = currentBlock;
            thugs[i].spent = 0;
        }
        for(uint256 i = 0; i < cops.length; i++){
            owed += ((currentBlock - cops[i].value) * cops[i].currentEarningRate) / 1 days - cops[i].spent;
            cops[i].value = currentBlock;
            cops[i].spent = 0;
        }
        deposited[_addr] = 0;
        bills.mint(_addr, owed);
        emit Withdraw(_addr, owed);
    }

    //MISC: Allow users to deposit only up to users available balance
    function depositBills(address _addr, uint256 amount) external whenNotPaused {
        require(tx.origin == msg.sender && msg.sender == _addr);
        require(amount > 0);
        require(bills.balanceOf(msg.sender) >= amount);
        bills.burn(msg.sender, amount);
        deposited[_addr] += amount;
        emit Deposit(msg.sender, amount);
    }

    function getTimestamp() external view virtual returns (uint256){
        return block.timestamp;
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
                earned += ((currentBlock - copStake[msg.sender][copCollection[tokenId]].value) * copStake[msg.sender][copCollection[tokenId]].currentEarningRate) / 1 days - copStake[msg.sender][copCollection[tokenId]].spent;
                if(copStake[msg.sender][copCollection[tokenId]].location != 0) {
                    removeCopLocationStake(tokenId, copStake[msg.sender][copCollection[tokenId]].location);
                }
                Stake memory lastStake = copStake[msg.sender][copStake[msg.sender].length - 1];
                copStake[msg.sender][copCollection[tokenId]] = lastStake;
                copCollection[lastStake.tokenId] = copCollection[tokenId];
                copStake[msg.sender].pop();
                totalCopsStaked--;
                delete copCollection[tokenId];
                citizen.safeTransferFrom(address(this), msg.sender, tokenId, "");
            } else { // UNSTAKE THUG
                earned += ((currentBlock - thugStake[msg.sender][thugCollection[tokenId]].value) * thugStake[msg.sender][thugCollection[tokenId]].currentEarningRate) / 1 days - thugStake[msg.sender][thugCollection[tokenId]].spent;
                Stake memory lastStake = thugStake[msg.sender][thugStake[msg.sender].length - 1];
                thugStake[msg.sender][thugCollection[tokenId]] = lastStake;
                thugCollection[lastStake.tokenId] = thugCollection[tokenId];
                thugStake[msg.sender].pop();
                totalThugsStaked--;
                delete thugCollection[tokenId];
                citizen.safeTransferFrom(address(this), msg.sender, tokenId, "");
            }
        }
        deposited[msg.sender] += earned;
        if(withdrawAllFunds) withdrawAll(msg.sender);
    }

    function crime(uint256 tokenId, uint256 location) external whenNotPaused  {
        require(!citizen.isCop(tokenId));
        require(assets.getGuns(tokenId) >= location);
        require(spend(msg.sender, prices[location-1]) == 0);
        uint256 reward = 0;
        uint256 rand = getRandomNumber(tokenId, 100);
        if(rand < chance){ // thug wins
            if(rand <= 50) { // smaller reward
                reward = 1;
            }else{ // bigger reward
                reward = 2;
            }
            assets.addReward(tokenId, location, reward);
        }else {
            locationPointTracker[location] += location;
        }

        if(location == 4){
            emit CrimeCommitted(tokenId, location, reward, bankStakedCops);
        }else if(location == 3){
            emit CrimeCommitted(tokenId, location, reward, casinoStakedCops);
        }else if(location == 2){
            emit CrimeCommitted(tokenId, location, reward, prisonStakedCops);
        }else if(location == 1){
            emit CrimeCommitted(tokenId, location, reward, dealershipStakedCops);
        }
    }


    // ROBBING: User buys gun at gun store
    function buyGun(uint256 tokenId, uint256 amount) public whenNotPaused {
        uint256 spending = gunCost*amount;
        require(ownerOfStaked[tokenId] == msg.sender);
        require(spend(msg.sender, spending) == 0);
        assets.addGun(tokenId, amount);
        emit GunPurchased(tokenId, amount);
    }

    // SPENDING: User spends $BILLS
    // NEEDS TO BE TESTED WITHOUT DEPOSITED FUNDS
    function spend(address _addr, uint256 amount) internal nonReentrant returns (uint256 spending) {
        Stake[] storage thugs = thugStake[_addr];
        Stake[] storage cops = copStake[_addr];
        spending = amount;
        require(getUserBalance(_addr) >= amount);
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
                uint256 owed = ((currentBlock - thugs[i].value) * thugs[i].currentEarningRate) / 1 days - thugs[i].spent;
                if(owed >= spending){
                    thugs[i].spent += spending;
                    spending = 0;
                }else{
                    spending -= owed;
                    thugs[i].spent = 0;
                    thugs[i].value = currentBlock;
                }
                if(spending == 0) break;
            }
            if(spending != 0){
                for(uint256 i = 0; i < cops.length; i++){
                    uint256 owed = ((currentBlock - cops[i].value) * cops[i].currentEarningRate) / 1 days - cops[i].spent;
                    if(owed >= spending){
                        cops[i].spent += spending;
                        spending = 0;
                    }else{
                        spending -= owed;
                        cops[i].spent = 0;
                        cops[i].value = currentBlock;
                    }
                    if(spending == 0) break;
                }
            }
        }
    }

    function removeCopLocationStake(uint256 tokenId, uint256 _location) internal {
        assets.addMedallion(tokenId, locationPointTracker[_location] - copStake[ownerOfStaked[tokenId]][copCollection[tokenId]].locationPoints);
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
    function rescue(uint256[] calldata tokenIds) external nonReentrant whenNotPaused {
        require(rescueEnabled);
        uint256 tokenId;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (citizen.isCop(tokenId)) {
                require(copStake[msg.sender][copCollection[tokenId]].owner == msg.sender);

                Stake memory lastStake = copStake[msg.sender][copStake[msg.sender].length - 1];
                copStake[msg.sender][copCollection[tokenId]] = lastStake;
                copCollection[lastStake.tokenId] = copCollection[tokenId];
                copStake[msg.sender].pop();

                totalCopsStaked--;
                delete copCollection[tokenId];
                citizen.safeTransferFrom(address(this), msg.sender, tokenId,"");
            } else {
                
                require(thugStake[msg.sender][thugCollection[tokenId]].owner == msg.sender);

                Stake memory lastStake = thugStake[msg.sender][thugStake[msg.sender].length - 1];
                thugStake[msg.sender][thugCollection[tokenId]] = lastStake;
                thugCollection[lastStake.tokenId] = thugCollection[tokenId];
                thugStake[msg.sender].pop();

                totalThugsStaked--;
                delete thugCollection[tokenId];
                citizen.safeTransferFrom(address(this),msg.sender,tokenId,"");
            }
        }
    }

    // GETTERS //

    function getUserPoints(address _user) public view virtual returns (uint256 points){
        for(uint256 i = 0; i < thugStake[_user].length; i++){
            points += assets.getPoints(thugStake[_user][i].tokenId);
        }
        for(uint256 i = 0; i < copStake[_user].length; i++){
            points += assets.getPoints(copStake[_user][i].tokenId);
        }
    }

    // Returns balance of given tokenId
    function getBalance(uint256 tokenId) public view virtual returns (uint256 balance){
        balance = 0;
        uint256 currentBlock = block.timestamp;
        if(block.timestamp > lastBlockTimestamp){
            currentBlock = lastBlockTimestamp;
        }
        if(citizen.isCop(tokenId)){
            balance += ((currentBlock - copStake[msg.sender][copCollection[tokenId]].value) * copStake[msg.sender][copCollection[tokenId]].currentEarningRate) / 1 days - copStake[msg.sender][copCollection[tokenId]].spent;
        }else{
            balance += ((currentBlock - thugStake[msg.sender][thugCollection[tokenId]].value) * thugStake[msg.sender][thugCollection[tokenId]].currentEarningRate) / 1 days - thugStake[msg.sender][thugCollection[tokenId]].spent;
        }
    }

    // NEEDS TO BE TESTED
    function getUserBalance(address _addr) public view virtual returns (uint256 balance) {
        balance = 0;
        uint256 currentBlock = block.timestamp;
        if(block.timestamp > lastBlockTimestamp){
            currentBlock = lastBlockTimestamp;
        }
        for(uint256 i = 0; i < thugStake[_addr].length; i++){
            balance += ((currentBlock - thugStake[_addr][i].value) * thugStake[_addr][i].currentEarningRate) / 1 days - thugStake[_addr][i].spent;
        }
        for(uint256 i = 0; i < copStake[_addr].length; i++){
            balance += ((currentBlock - copStake[_addr][i].value) * copStake[_addr][i].currentEarningRate) / 1 days - copStake[_addr][i].spent;
        }
        balance += deposited[_addr];
    }

    function getUnclaimedMedallions(uint256 tokenId) public view virtual returns (uint256) {
        return locationPointTracker[copStake[ownerOfStaked[tokenId]][copCollection[tokenId]].location] - copStake[ownerOfStaked[tokenId]][copCollection[tokenId]].locationPoints;
    }

    function getUserStakedThugs(address _addr) public view virtual returns(uint256[] memory){
        uint256[] memory tokenIds = new uint256[](thugStake[_addr].length);
        for(uint256 i = 0; i < thugStake[_addr].length; i++){
            tokenIds[i] = thugStake[_addr][i].tokenId;
        }
        return tokenIds;
    }

    function getUserStakedCops(address _addr) public view virtual returns(uint256[] memory){
        uint256[] memory tokenIds = new uint256[](copStake[_addr].length);
        for(uint256 i = 0; i < copStake[_addr].length; i++){
            tokenIds[i] = copStake[_addr][i].tokenId;
        }
        return tokenIds;
    }

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

    function setLastTimestamp(uint256 _timestamp) external onlyOwner {
        lastBlockTimestamp = _timestamp;
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

    function setChance(uint256 _chance) external onlyOwner {
        chance = _chance;
    }


    //MISC: Get random number
    function getRandomNumber(uint256 _seed, uint256 _limit) internal view returns (uint256) {
        uint256 extra = 0;
        for (uint256 i = 0; i < 5; i++) {
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
                    //extra,
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