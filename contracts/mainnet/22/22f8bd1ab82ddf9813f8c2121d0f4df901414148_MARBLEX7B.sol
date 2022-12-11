/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// $$\      $$\                     $$\       $$\                               $$\                 $$$$$$$\             $$\     $$\     $$\                     
// $$$\    $$$ |                    $$ |      $$ |                              \__|                $$  __$$\            $$ |    $$ |    \__|                    
// $$$$\  $$$$ | $$$$$$\   $$$$$$\  $$$$$$$\  $$ | $$$$$$\   $$$$$$\   $$$$$$\  $$\ $$\   $$\       $$ |  $$ | $$$$$$\ $$$$$$\ $$$$$$\   $$\ $$$$$$$\   $$$$$$\  
// $$\$$\$$ $$ | \____$$\ $$  __$$\ $$  __$$\ $$ |$$  __$$\ $$  __$$\ $$  __$$\ $$ |\$$\ $$  |      $$$$$$$\ |$$  __$$\\_$$  _|\_$$  _|  $$ |$$  __$$\ $$  __$$\ 
// $$ \$$$  $$ | $$$$$$$ |$$ |  \__|$$ |  $$ |$$ |$$$$$$$$ |$$ /  $$ |$$ |  \__|$$ | \$$$$  /       $$  __$$\ $$$$$$$$ | $$ |    $$ |    $$ |$$ |  $$ |$$ /  $$ |
// $$ |\$  /$$ |$$  __$$ |$$ |      $$ |  $$ |$$ |$$   ____|$$ |  $$ |$$ |      $$ | $$  $$<        $$ |  $$ |$$   ____| $$ |$$\ $$ |$$\ $$ |$$ |  $$ |$$ |  $$ |
// $$ | \_/ $$ |\$$$$$$$ |$$ |      $$$$$$$  |$$ |\$$$$$$$\ $$$$$$$  |$$ |      $$ |$$  /\$$\       $$$$$$$  |\$$$$$$$\  \$$$$  |\$$$$  |$$ |$$ |  $$ |\$$$$$$$ |
// \__|     \__| \_______|\__|      \_______/ \__| \_______|$$  ____/ \__|      \__|\__/  \__|      \_______/  \_______|  \____/  \____/ \__|\__|  \__| \____$$ |
//                                                          $$ |                                                                                       $$\   $$ |
//                                                          $$ |                                                                                       \$$$$$$  |
//                                                          \__|                                                                                        \______/ 

// SPDX-License-Identifier: MIT
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.7;

contract MARBLEX7B{

    address public adminAddress; // address of the admin
    address public operatorAddress; // address of the operator
    address public tokenAddress; // address of the betb token
    bool public pause;
    uint256 public intervalSeconds; // interval in seconds between two prediction rounds
    uint256 public bufferSeconds; // number of seconds for valid execution of a prediction round
    uint256 public currentRace; 
    uint256 public minTokenAmount;
    uint256 public minRacePrice;

    struct Marble{
        uint256 marbleId;
        string color; // color name or RGB notation for dynamic color in frontend
        uint256 totalBet; //Bet on individual Marble by all players 
        //bool isActive;
    }

    struct Race {
        uint256[] marbles; 
        bool paidOut; // after a race is paidOut it can be considered done
        uint256 startTimestamp; //unix timestamp
        uint256 lockTimestamp; //unix timestamp
        uint256 closeTimestamp; //unix timestamp
        uint256[] bets;
        int winnerIdInMarbleIdToRace; // -1 until a winner is determined
        uint256 totalBet; //Bet on all Marbles by all players
        uint256 price; //price of the race
        bool voidRace;
    }

    struct Bet {
        address payable bettorAddr;//bettor address
        bool rewarded; // if true, person already has been rewarded
        uint256 idInMarbleIdToRace; //marble on which better is betting
        uint256 betAmount; //amount they bet
        uint256 raceId;
    }

    struct BetInfo {
        uint256 marbleId;
        uint256 amount;
        bool withdraw; // default false
        uint256 count;
    }

    mapping(address => bool) authorized;

    // lookup betIds from the uint256[] of bets in Race structs
    mapping(uint256 => Bet) public betIdToBet;
    mapping(uint256 => Marble) public superSetmMarbles;
    mapping(uint256 => Race) public races;
    mapping(uint256 => mapping(address => BetInfo)) public betledger;
    mapping(address => uint256[]) public userRounds;
    mapping(uint256 => mapping(uint256 => Marble)) public marbleIdToRace;

    uint256 betsInSystem = 0;
    uint256 marblesRaceInSystem = 0;
    uint256 totalMarbles;

    address payable public ecoSystemWallet ;
    uint256 public ecoSystemFeePercentage;
    

    constructor(address payable _ecoSystemAddress, uint256 _ecoSystemFeePercentage, address _tokenAddress){
        superSetmMarbles[1] = Marble(1,"Red Rhinos",0); // RGB notation to pick the color from frontend
        superSetmMarbles[2] = Marble(2,"Yellow Eagle",0);
        superSetmMarbles[3] = Marble(3,"Grey Cheetah",0);
        superSetmMarbles[4] = Marble(4,"Dashing Dragon",0);
        superSetmMarbles[5] = Marble(5,"Pink Panther",0);
        superSetmMarbles[6] = Marble(6,"Blue Zeebra",0);
        superSetmMarbles[7] = Marble(7,"Brown Tiger",0);
        totalMarbles = 7;
        ecoSystemWallet = _ecoSystemAddress;
        ecoSystemFeePercentage= _ecoSystemFeePercentage;
        authorized[msg.sender] = true;
        authorized[_ecoSystemAddress] = true;

        adminAddress = msg.sender;
        operatorAddress = msg.sender;
        tokenAddress = _tokenAddress;
        minTokenAmount = 200000000000000000000000;
        pause = false;
        intervalSeconds = 15*60; //racetime+15mins
        bufferSeconds = 30*60; //racetime+30mins
        currentRace = 0;
        minRacePrice = 9000000000000000;
    }

    event StartRound(uint256 indexed race);
    event VoidRound(uint256 indexed race, bool status);

    modifier onlyAuthorized
    {
        require( authorized[msg.sender] == true, "Not Authorized to call...!" );
        _;
    }

    modifier whenNotPaused() {
        require(pause == false, "Contract is pause");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Not admin");
        _;
    }

    modifier onlyAdminOrOperator() {
        require(msg.sender == adminAddress || msg.sender == operatorAddress, "Not operator/admin");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Not operator");
        _;
    }

    function isAuthorized(address _address) public view returns(bool) {
        return authorized[_address];
    }
     function getNumberOfBetsOnRace(uint256 _raceIndex) public view returns(uint256) {
        return races[_raceIndex].bets.length;
    }

    function getNumberOfMarblesInRace(uint256 _raceIndex) public view returns(uint256) {
        return races[_raceIndex].marbles.length;
    }

    function getAvailableMarbleIdsInRace(uint256 _raceIndex) public view returns(uint256[] memory) {
        return races[_raceIndex].marbles;
    }

    function getNumberOfBetsInRace(uint256 _raceIndex) public view returns(uint256[] memory) {
        return races[_raceIndex].bets;
    }
   
    function getTotalBetInRace(uint256 _raceIndex) public view returns(uint256) {
        return races[_raceIndex].totalBet;
    }
    
    function authorize(address _address) public onlyOperator {
        authorized[_address] = true;
    }

    function unAuthorize(address _address) public onlyOperator {
        authorized[_address] = false;
    }

    function setEcoSystemWallet(address payable _ecoSystemAddress, uint256 _ecoSystemFeePercentage) public onlyAdmin {
        ecoSystemWallet = _ecoSystemAddress;
        ecoSystemFeePercentage= _ecoSystemFeePercentage;
    }

    function setBetClamCond(address _tokenAddress, uint256 _minTokenAmount) public onlyAdmin {
        tokenAddress = _tokenAddress;
        minTokenAmount = _minTokenAmount;
    }

    function pauseContract(bool _status) public onlyAdmin {
        pause = _status;
    }

    function setAdmin(address _adminAddress, address _operatorAddress) public onlyAdmin {
        adminAddress = _adminAddress;
        operatorAddress = _operatorAddress;
    }

    function setIntialValues(uint256 _intervalSeconds, uint256 _bufferSeconds, uint256 _minRacePrice) public onlyOperator {
        intervalSeconds = _intervalSeconds;
        bufferSeconds = _bufferSeconds;
        minRacePrice = _minRacePrice;
    }

    function AddMarble(string memory color) public onlyOperator{
        totalMarbles++;
        superSetmMarbles[totalMarbles] = Marble(totalMarbles, color, 0);
    }

    function GetUnStuckBalance(address receiver, uint256 amountToWithdraw) public onlyAdmin{
        uint256 amount = (amountToWithdraw <= address(this).balance) ? amountToWithdraw : address(this).balance;
        payable(receiver).transfer(amount);
    }

    function sort_array(uint256[] memory arr) private pure returns (uint256[] memory _sortArray) {
        uint256 l = arr.length;
        for(uint i = 0; i < l; i++) {
            for(uint j = i+1; j < l ;j++) {
                if(arr[i] > arr[j]) {
                    uint256 temp = arr[i];
                    arr[i] = arr[j];
                    arr[j] = temp;
                }
            }
        }
        return arr;
    }

    function removeDuplicateRaces(uint256[] memory _marbleIds) public view returns(uint256[] memory _distinctMarbleIds)
    {
        uint256[] memory _sortArray = sort_array(_marbleIds);
        uint256[] memory distinctMarbleIds = new uint256[](_sortArray.length) ;
        uint256 k = 0;
             
        for(uint256 i=0; i< (_sortArray.length);i++)
        {
            bool isExistsOrInvalid = false;
            uint256 id = _sortArray[i];
            if( 0 < id && id <= totalMarbles)
            {
                for(int256 j= int256(i)-1; j >= 0 ;j--)
                {
                    if(( id ==_sortArray[uint256(j)]) && (i!= uint256(j) ) )
                    {
                        isExistsOrInvalid = true;                        
                    }
                }
            }
            else{
                isExistsOrInvalid = true;
            }
            if(!isExistsOrInvalid){ 
                distinctMarbleIds[k] = id;
                k++;
            }
            
        }
        return removeZeroEntries(distinctMarbleIds, k);
    }
    
    function removeZeroEntries(uint256[] memory _marbleIds, uint256 nonZerolength) public pure returns(uint256[] memory _nonZeroMarblesInRace)
    {
        require(nonZerolength <= _marbleIds.length, "non ZeroValues length is greater than actual array size..!");
        uint256[] memory nonZeroMarblesInRace = new uint256[](nonZerolength);

        uint256 j = 0;
        for(uint256 i=0; i< _marbleIds.length && j< nonZerolength; i++)
        {
            uint256 id = _marbleIds[i];
            if( id != 0)
            {
                nonZeroMarblesInRace[j] = id;
                j++;
            }
        }

        return nonZeroMarblesInRace;
    }

    function newRace(uint256[] memory _marbleIds, uint256 _raceTime, uint256 _racePrice) public whenNotPaused onlyAdminOrOperator {
        require( _marbleIds.length >= 7 , "Atleast 7 marbles!");
        require(_raceTime > block.timestamp, "Race must take place for future");
        require(_racePrice > minRacePrice, "price must be greater than min limit");

        uint256[] memory bets;
        uint256[] memory _distinctMarbleIds = removeDuplicateRaces(_marbleIds);

        currentRace = currentRace + 1;

        races[currentRace] = Race(_distinctMarbleIds, false, _raceTime, _raceTime + intervalSeconds, _raceTime + bufferSeconds, bets, -1, 0, _racePrice, false);

        emit StartRound(currentRace);
    }

    function setVoidRace(uint256 _raceIndex, bool _status) public whenNotPaused onlyAdminOrOperator {
        require(races[_raceIndex].closeTimestamp > block.timestamp, "Race already finished");
        Race storage races = races[_raceIndex];
        races.voidRace = _status;

        emit VoidRound(_raceIndex, _status);
    }

    function claimBetAmt(uint256 _raceIndex) public {
        require(races[_raceIndex].voidRace, "race is not yet void");
        require(betledger[_raceIndex][msg.sender].amount > 0, " no bet is placed in this round");
        require(!betledger[_raceIndex][msg.sender].withdraw, "amount already withdrawn for this round");

         
        payable(msg.sender).transfer(betledger[_raceIndex][msg.sender].amount);
        betledger[_raceIndex][msg.sender].withdraw = true;
    }

    function createBet(uint256 _raceIndex, uint256 _marbleIndex) public payable{
        require(races[_raceIndex].price == msg.value, "price is wrong");
        require(races[_raceIndex].startTimestamp < block.timestamp, "race is not yet started");
        require(races[_raceIndex].lockTimestamp > block.timestamp, "race is already locked");
        require(!races[_raceIndex].voidRace, "race is already void");
        bool exists = false;
        for (uint i = 0; i < races[_raceIndex].marbles.length; i++) {
            if (races[_raceIndex].marbles[i] == _marbleIndex) {
                exists = true;
            }
        }
        require(exists, "_marbleIndex not exists!");
        if(minTokenAmount > 0) {
            require(IERC20(tokenAddress).balanceOf(msg.sender) >= minTokenAmount, "token Balance limit fail");
        }

        betsInSystem++;
        uint256 newBetId = (betsInSystem);

        // Update user data
        BetInfo storage betInfo = betledger[_raceIndex][msg.sender];
        // betledger[_raceIndex][msg.sender].marbleId[betledger[_raceIndex][msg.sender].count+1] = _marbleIndex;
        betInfo.marbleId = _marbleIndex;
        betInfo.amount += msg.value;
        betInfo.withdraw = false;
        betInfo.count += 1;

        userRounds[msg.sender].push(_raceIndex);

        races[_raceIndex].totalBet += msg.value; //adding total amount for all marbles in race
        marbleIdToRace[_raceIndex][_marbleIndex].totalBet += msg.value; //adding participants amount for indvidual marbles in race
        betIdToBet[newBetId] = Bet(payable(msg.sender), false, _marbleIndex, msg.value, _raceIndex);
        races[_raceIndex].bets.push(newBetId);
    }

    function getUserRounds(address _add) public view returns(uint256[] memory) {
        return userRounds[_add];
    }

    // do we need ths as a payable? as we are not specifying how much to send and sending from self wallet
    function evaluateRace(uint256 _raceIndex, uint256 _winnerMarbleIndex ) public onlyAdminOrOperator {
        // require(races[_raceIndex].closeTimestamp < block.timestamp, "Race not yet finished");
        require(races[_raceIndex].paidOut == false, "Race already evaluated");
        require(!races[_raceIndex].voidRace, "race is already void");

        uint256 _totalRaceBet = races[_raceIndex].totalBet;
        uint256 _totalWinnerMarbleBet = marbleIdToRace[_raceIndex][_winnerMarbleIndex].totalBet;

        uint256 _ecoSystemBalance = (_totalRaceBet * ecoSystemFeePercentage) > 100 ? (_totalRaceBet * ecoSystemFeePercentage) / 100 : 0;
        uint256 _remainingBalance = _totalRaceBet - _ecoSystemBalance;

        ecoSystemWallet.transfer(_ecoSystemBalance);
        
        if( (races[_raceIndex].bets.length > 0) && (_totalWinnerMarbleBet > 0) ){
            uint256 _multiplierPercentage = (_remainingBalance * 100) /  _totalWinnerMarbleBet;
            for(uint256 i = 0; i < races[_raceIndex].bets.length; i++){
                Bet memory tempBet = betIdToBet[races[_raceIndex].bets[i]];
                if(tempBet.idInMarbleIdToRace == _winnerMarbleIndex) {
                    uint256 _betAmount = tempBet.betAmount;
                    uint256 winAmount = (_betAmount * _multiplierPercentage) > 100 ? (_betAmount * _multiplierPercentage) / 100 : 0;
                    require(address(this).balance >= winAmount, "Not enough funds to reward bettor");
                    tempBet.bettorAddr.transfer(winAmount);
                }
            }
        }

        races[_raceIndex].paidOut = true;
        races[_raceIndex].winnerIdInMarbleIdToRace =  int(_winnerMarbleIndex);
    }
    receive() payable external {}
}