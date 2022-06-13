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

//INTERFACE: Leaderboard contract
interface ILeaderboard {
    function addGun(uint256 tokenId, uint256 amount) external;
    function addMedallion(uint256 tokenId, uint256 amount) external;
    function addCash(uint256 tokenId) external;
    function addCashBag(uint256 tokenId) external;
    function addChips(uint256 tokenId) external;
    function addChipStacks(uint256 tokenId) external;
    function addStreetThugs(uint256 tokenId) external;
    function addGangLeaders(uint256 tokenId) external;
    function addSportsCar(uint256 tokenId) external;
    function addSuperCar(uint256 tokenId) external;
    function getPoints(uint256 tokenId) external view returns (uint256);
    function getGuns(uint256 tokenId) external view returns (uint256);
}

contract City is Ownable, IERC721Receiver, ReentrancyGuard {

    //EVENTS: Emitted upon completion of action
    event Deposit(address from, uint256 amount);
    event Withdraw(address to, uint256 tokenId, uint256 amount);
    event WithdrawAll(address _addr, uint256 owed);
    event CrimeCommitted(uint256 tokenId, uint256 location, uint256 reward);
    event GunPurchased(uint256 tokenId, uint256 amount);
    event Staked(uint256[] tokenIds);
    event CopMoved(uint256 tokenId, uint256 location);

    bool private _paused = false;
    uint256 public chance = 50;

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
        uint256 currentEarningRate;
    }

    //**HARDCODE**: Initialize citizen CHANGE TO PARAM FOR MAINNET
    IThugCityNFT public citizen = IThugCityNFT(0x2C19D9c7ff4c855EaE3e7052563282BbbcB8D0c7);

    //**HARDCODE**: Initialize bills CHANGE TO PARAM FOR MAINNET
    IBills public bills = IBills(0x11E7bAF1beC2Bb11E477E805029C077F20ee67f9);

    //**HARDCODE**: Initialize leaderboard CHANGE TO PARAM FOR MAINNET
    ILeaderboard public leaderboard = ILeaderboard(0x3045a89FBEf5B76EA02231A8D12CCc6B5F6f5Eb1);

    //DECLARE: Map cops to stake and location
    mapping(uint256 => uint256) public copCollection;
    mapping(address => Stake[]) public copStake;

    // Mappings index cop position in stakedCops array
    mapping(uint256 => uint256) public copBankCollection; //Stake location 1
    mapping(uint256 => uint256) public copCasinoCollection; //Stake location 2
    mapping(uint256 => uint256) public copPrisonCollection; //Stake location 3
    mapping(uint256 => uint256) public copDealershipCollection; //Stake location 4

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

    mapping(address => uint256) public deposited;

    //DECLARE: Total total thugs and cops staked
    uint256 public totalCopsStaked;
    uint256 public totalThugsStaked;

    //DECLARE: Daily rates, crime prices and maximums
    uint256 private DAILY_BILLS_RATE = 10000 ether;
    uint256 private DAILY_COP_BILLS_RATE = 12000 ether;
    uint256[] private prices = [2000 ether, 3000 ether, 4000 ether, 5000 ether];
    uint256 private gunCost = 1000 ether;
    uint256 private copGunCost = 800 ether;

    //DECLARE: Emergency rescue to allow unstaking without $BILLS
    bool public rescueEnabled = false;
    mapping(uint256 => uint256) public rescueBalances;

    //CONSTRUCTOR: Sets addresses for other contracts
    constructor(/*address _citizen, address _bills, address _leaderboard*/) {
        //setContracts(_citizen, _bills, _leaderboard);
        _randomSource[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        _randomSource[1] = 0x3cD751E6b0078Be393132286c442345e5DC49699;
        _randomSource[2] = 0xC098B2a3Aa256D2140208C3de6543aAEf5cd3A94;
        _randomSource[3] = 0x28C6c06298d514Db089934071355E5743bf21d60;
        _randomSource[4] = 0x267be1C1D684F78cb4F6a176C4911b741E4Ffdc0;
    }

    //STAKING: Adds cops and/or thugs to thugcity (cops added to cop station, location = 0
    function addManyToCity(address account, uint256[] calldata tokenIds) external nonReentrant whenNotPaused {
        require(account == msg.sender);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] != 0);
            require(!staked[tokenIds[i]]);
            require(citizen.ownerOf(tokenIds[i]) == msg.sender); // checking with NFT contract for ownership
            citizen.transferFrom(msg.sender, address(this), tokenIds[i]);

            if (citizen.isCop(tokenIds[i])) {
                Stake memory stake = Stake({
                        owner: account,
                        tokenId: uint256(tokenIds[i]),
                        value: block.timestamp,
                        spent: 0,
                        location: 0,
                        currentEarningRate: DAILY_COP_BILLS_RATE
                        });
                totalCopsStaked++;
                copCollection[tokenIds[i]] = copStake[account].length;
                staked[tokenIds[i]] = true;
                copStake[account].push(stake);
            } else {
                Stake memory stake = Stake({
                        owner: account,
                        tokenId: uint256(tokenIds[i]),
                        value: block.timestamp,
                        spent: 0,
                        location: 0,
                        currentEarningRate: DAILY_BILLS_RATE
                        });
                totalThugsStaked++;
                thugCollection[tokenIds[i]] = thugStake[account].length;
                staked[tokenIds[i]] = true;
                thugStake[account].push(stake);
            }
        }
        emit Staked(tokenIds);
    }

    // Can use to boost certain people for community actions
    // Needs to be tested
    function updateEarningsRate(uint256[] calldata tokenIds, uint256 newRate, uint256 multiplier) external onlyOwner {
        for(uint i = 0; i < tokenIds.length; i++){
            Stake storage stake;
            if(citizen.isCop(tokenIds[i])){
                stake = copStake[msg.sender][copCollection[tokenIds[i]]];
            }else{
                stake = copStake[msg.sender][thugCollection[tokenIds[i]]];
            }
            deposited[msg.sender] += ((block.timestamp - stake.value) * stake.currentEarningRate) / 1 days - stake.spent;
            stake.value = block.timestamp;
            if(multiplier == 0){
                stake.currentEarningRate = newRate;
            }else{
                stake.currentEarningRate = stake.currentEarningRate * multiplier;
            }
        }
    }


    //COP STAKING: Moves cop to specified location
    function stakeCopAtLocation(address account, uint256 tokenId, uint256 stakeLocation) external nonReentrant whenNotPaused {
        require(account == msg.sender);
        require(citizen.isCop(tokenId));
        Stake storage stake;
        require(leaderboard.getGuns(tokenId) >= stakeLocation, "Not enough guns!");
        if(staked[tokenId]){
            stake = copStake[msg.sender][copCollection[tokenId]];
            require(stake.owner == msg.sender, "Must be owner of NFT!");
            require(stake.location != stakeLocation, "Cannot move to same location!");
            if(stake.location != 0){
                removeCopLocationStake(tokenId, stake.location);
            }
            stake.location = stakeLocation;
        }else{
            citizen.transferFrom(msg.sender, address(this), tokenId);
            totalCopsStaked++;
            copCollection[tokenId] = copStake[account].length;
            staked[tokenId] = true;
            copStake[account].push(Stake({
                owner: account,
                tokenId: uint256(tokenId),
                value: block.timestamp,
                spent: 0,
                location: stakeLocation,
                currentEarningRate: DAILY_COP_BILLS_RATE
                }));
        }
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
    function withdrawFrom(uint256 tokenId) public nonReentrant {
        uint256 owed;
        uint256 withdrew;
        require(staked[tokenId]);
        require(ownerOfStaked(tokenId,msg.sender));
        Stake storage stake;
        if (citizen.isCop(tokenId)) {
            stake = copStake[msg.sender][copCollection[tokenId]];
        } else {
            stake = thugStake[msg.sender][thugCollection[tokenId]];
        }
        // gets owed amount
        owed = ((block.timestamp - stake.value) * stake.currentEarningRate) / 1 days - stake.spent;
        stake.value = block.timestamp; // resets timestamp
        bills.mint(msg.sender, owed - stake.spent); // mints owed amount - spent amount
        withdrew = owed - stake.spent;
        stake.spent = 0; // resets spent amount
        emit Withdraw(msg.sender, tokenId, withdrew); // emits output of withdrawal
    }

    function withdrawAll(address _addr) public nonReentrant {
        require(msg.sender == _addr);
        Stake[] storage thugs = thugStake[_addr];
        Stake[] storage cops = copStake[_addr];
        uint256 owed = deposited[_addr];
        for(uint256 i = 0; i < thugs.length; i++){
            owed += ((block.timestamp - thugs[i].value) * thugs[i].currentEarningRate) / 1 days - thugs[i].spent;
            thugs[i].value = block.timestamp;
            thugs[i].spent = 0;
        }
        for(uint256 i = 0; i < cops.length; i++){
            owed += ((block.timestamp - cops[i].value) * cops[i].currentEarningRate) / 1 days - cops[i].spent;
            cops[i].value = block.timestamp;
            cops[i].spent = 0;
        }
        deposited[_addr] = 0;
        bills.mint(_addr, owed);
        emit WithdrawAll(_addr, owed);
    }

    // Returns balance of given tokenId
    function getBalance(uint256 tokenId) public view virtual returns (uint256 balance){
        balance = 0;
        if(citizen.isCop(tokenId)){
            balance += ((block.timestamp - copStake[msg.sender][copCollection[tokenId]].value) * copStake[msg.sender][copCollection[tokenId]].currentEarningRate) / 1 days - copStake[msg.sender][copCollection[tokenId]].spent;
        }else{
            balance += ((block.timestamp - thugStake[msg.sender][thugCollection[tokenId]].value) * thugStake[msg.sender][thugCollection[tokenId]].currentEarningRate) / 1 days - thugStake[msg.sender][thugCollection[tokenId]].spent;
        }
    }

    // NEEDS TO BE TESTED
    function getUserBalance(address _addr) public view virtual returns (uint256 balance) {
        balance = 0;
        for(uint256 i = 0; i < thugStake[_addr].length; i++){
            balance += ((block.timestamp - thugStake[_addr][i].value) * thugStake[_addr][i].currentEarningRate) / 1 days - thugStake[_addr][i].spent;
        }
        for(uint256 i = 0; i < copStake[_addr].length; i++){
            balance += ((block.timestamp - copStake[_addr][i].value) * copStake[_addr][i].currentEarningRate) / 1 days - copStake[_addr][i].spent;
        }
        balance += deposited[_addr];
    }

    //MISC: Allow users to deposit only up to users available balance
    // NON reentrant is unneccessary
    function depositBills(address _addr, uint256 amount) external nonReentrant {
        require(_addr == msg.sender);
        require(amount > 0);
        require(bills.balanceOf(msg.sender) >= amount);
        bills.burn(msg.sender, amount);
        deposited[_addr] += amount;
        emit Deposit(msg.sender, amount);
    }

    //UNSTAKING: Unstake and claim from thugs and cops
    function unstakeManyFromCity(uint256[] calldata tokenIds, bool withdrawAllFunds) external whenNotPaused {
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if(!withdrawAllFunds) withdrawFrom(tokenIds[i]);
            require(staked[tokenIds[i]]);
            uint256 tokenId = tokenIds[i];
            if (citizen.isCop(tokenId)) {
                require(copStake[msg.sender][copCollection[tokenId]].owner == msg.sender);
                if(copStake[msg.sender][copCollection[tokenId]].location != 0) {
                    removeCopLocationStake(tokenId, copStake[msg.sender][copCollection[tokenId]].location);
                }
                Stake memory lastStake = copStake[msg.sender][copStake[msg.sender].length - 1];
                copStake[msg.sender][copCollection[tokenId]] = lastStake;
                copCollection[lastStake.tokenId] = copCollection[tokenId];
                copStake[msg.sender].pop();
                staked[tokenId] = false;
                totalCopsStaked--;
                delete copCollection[tokenId];
                citizen.safeTransferFrom(address(this), msg.sender, tokenId, "");
            } else { // UNSTAKE THUG
                require(thugStake[msg.sender][thugCollection[tokenId]].owner == msg.sender);
                Stake memory lastStake = thugStake[msg.sender][thugStake[msg.sender].length - 1];
                thugStake[msg.sender][thugCollection[tokenId]] = lastStake;
                thugCollection[lastStake.tokenId] = thugCollection[tokenId];
                thugStake[msg.sender].pop();
                totalThugsStaked--;
                delete thugCollection[tokenId];
                staked[tokenId] = false;
                citizen.safeTransferFrom(address(this), msg.sender, tokenId, "");
            }
        }
        if(withdrawAllFunds) withdrawAll(msg.sender);
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

    function getLocationStakedCops(address _addr, uint256 _location) public view virtual returns(uint256[] memory){
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

    function setChance(uint256 _chance) external onlyOwner {
        chance = _chance;
    }

    function getCopLocation(address _tokenOwner, uint256 tokenId) public view virtual returns(uint256){
        return copStake[_tokenOwner][copCollection[tokenId]].location;
    }

    function crime(uint256 tokenId, uint256 location) external whenNotPaused  {
        require(!citizen.isCop(tokenId));
        require(leaderboard.getGuns(tokenId) >= location);
        require(spend(msg.sender, prices[location-1]) == 0);
        uint256 reward = 0;
        uint256 rand = getRandomNumber(tokenId, 100);
        if(rand < chance){ // thug wins
            if(rand <= 50) { // smaller reward
                reward = 1;
            }else{ // bigger reward
                reward = 2;
            }
        }

        if(location == 4){
            if(reward == 1){
                leaderboard.addCash(tokenId);
            }else if(reward == 2){
                leaderboard.addCashBag(tokenId);
            }else {
                for(uint256 i = 0; i < bankStakedCops.length; i++){
                    leaderboard.addMedallion(bankStakedCops[i], 4);
                }
            }
            emit CrimeCommitted(tokenId, location, reward);
        }else if(location == 3){
            if(reward == 1){
                leaderboard.addChips(tokenId);
            }else if(reward == 2){
                leaderboard.addChipStacks(tokenId);
            }else {
                for(uint256 i = 0; i < casinoStakedCops.length; i++){
                    leaderboard.addMedallion(casinoStakedCops[i], 3);
                }
            }
            emit CrimeCommitted(tokenId, location, reward);
        }else if(location == 2){
            if(reward == 1){
                leaderboard.addStreetThugs(tokenId);
            }else if(reward == 2){
                leaderboard.addGangLeaders(tokenId);
            }else {
                for(uint256 i = 0; i < prisonStakedCops.length; i++){
                    leaderboard.addMedallion(prisonStakedCops[i], 2);
                }
            }
            emit CrimeCommitted(tokenId, location, reward);
        }else if(location == 1){
            if(reward == 1){
                leaderboard.addSportsCar(tokenId);
            }else if(reward == 2){
                leaderboard.addSuperCar(tokenId);
            }else {
                for(uint256 i = 0; i < dealershipStakedCops.length; i++){
                    leaderboard.addMedallion(dealershipStakedCops[i], 1);
                }
            }
            emit CrimeCommitted(tokenId, location, reward);
        }
    }


    // ROBBING: User buys gun at gun store
    function buyGun(uint256 tokenId, uint256 amount) public whenNotPaused {
        uint256 spending = gunCost*amount;
        require(ownerOfStaked(tokenId, msg.sender));
        if(citizen.isCop(tokenId))
            spending = copGunCost*amount;
        require(spend(msg.sender, spending) == 0);
        leaderboard.addGun(tokenId, amount);
        emit GunPurchased(tokenId, amount);
    }

    // NEEDS TO BE TESTED
    // ROBBING: Thug spend $BILLS at location
    function spend(address _addr, uint256 amount) internal nonReentrant returns (uint256 spending) {
        Stake[] storage thugs = thugStake[_addr];
        Stake[] storage cops = copStake[_addr];
        spending = amount;
        require(getUserBalance(_addr) >= amount);
        if(deposited[_addr] >= amount){
            deposited[_addr] -= spending;
            spending = 0;
        }else{
            spending -= deposited[_addr];
            deposited[_addr] = 0;
            for(uint256 i = 0; i < thugs.length; i++){
                uint256 owed = ((block.timestamp - thugs[i].value) * thugs[i].currentEarningRate) / 1 days - thugs[i].spent;
                if(owed >= spending){
                    thugs[i].spent += spending;
                    spending = 0;
                }else{
                    spending -= owed;
                    thugs[i].spent = 0;
                    thugs[i].value = block.timestamp;
                }
                if(spending == 0) break;
            }
            if(spending != 0){
                for(uint256 i = 0; i < cops.length; i++){
                    uint256 owed = ((block.timestamp - cops[i].value) * cops[i].currentEarningRate) / 1 days - cops[i].spent;
                    if(owed >= spending){
                        cops[i].spent += spending;
                        spending = 0;
                    }else{
                        spending -= owed;
                        cops[i].spent = 0;
                        cops[i].value = block.timestamp;
                    }
                    if(spending == 0) break;
                }
            }
        }
    }

    //OWNER: Set prices of locations
    function setLocationPrices(uint256 _bank, uint256 _casino, uint256 _prison, uint256 _dealership, uint256 _gunCop, uint256 _gunThug) external onlyOwner {
        prices[3] = _bank;
        prices[2] = _casino;
        prices[1] = _prison;
        prices[0] = _dealership;
        gunCost = _gunThug;
        copGunCost = _gunCop;
    }

    function ownerOfStaked(uint256 tokenId, address account) internal view returns(bool){
        require(staked[tokenId]);
        require(msg.sender == account);
        if(citizen.isCop(tokenId)){
            if(copStake[account][copCollection[tokenId]].owner != account) return false;
        }else{
            if(thugStake[account][thugCollection[tokenId]].owner != account) return false;
        }
        return true;
    }

    function removeCopLocationStake(uint256 tokenId, uint256 _location) internal {
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
            staked[tokenIds[i]] = false;
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

    //OWNER: Enabling rescue command
    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }

    //OWNER: Set contract addresses
    function setContracts(address _citizen, address _bills, address _leaderboard) public onlyOwner {
        citizen = IThugCityNFT(_citizen);
        bills = IBills(_bills);
        leaderboard = ILeaderboard(_leaderboard);
    }

    //OWNER: Enable pausing of minting
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