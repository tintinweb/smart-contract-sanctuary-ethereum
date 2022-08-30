/**
 *Submitted for verification at Etherscan.io on 2022-04-18
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '../interfaces/IUniswapV2Pair.sol';
import '../interfaces/IUniswapV2Factory.sol';
import '../interfaces/IUniswapV2Router.sol';
import '../interfaces/IPRC20.sol';
import '../interfaces/IPLSP.sol';

// File: PotContract.sol

contract PotLottery is ReentrancyGuardUpgradeable {
    /*
     ***Start of function, Enum, Variables, array and mappings to set and edit the Pot State such that accounts can enter the pot
     */
    using SafeMath for uint256;
    using SafeMath for uint256;

    struct Token {
        address tokenAddress;
        string tokenSymbol;
        uint256 tokenDecimal;
    }

    enum POT_STATE {
        PAUSED,
        WAITING,
        STARTED,
        LIVE,
        CALCULATING_WINNER
    }

    address public owner;
    address public admin;

    // This is for Rinkeby
    address public wethAddr;
    address public usdtAddr;
    address public uniswapV2FactoryAddr;
    IUniswapV2Router02 public router;

    POT_STATE public pot_state;

    mapping(string => Token) public tokenWhiteList;
    string[] public tokenWhiteListNames;
    uint256 public minEntranceInUsd;
    uint256 public potCount;
    uint256 public potDuration;
    uint256 public percentageFee;
    uint256 public PotEntryCount;
    uint256 public entriesCount;
    address public PLSP_Address;
    uint256 public PLSP_Standard;

    mapping(string => uint256) public tokenLatestPriceFeed;

    uint256 public potLiveTime;
    uint256 public potStartTime;
    uint256 public timeBeforeRefund;
    uint256 public participantCount;
    address[] public participants;
    string[] public tokensInPotNames;
    uint256 public totalPotUsdValue;
    address[] public entriesAddress;
    uint256[] public entriesUsdValue;
    address public LAST_POT_WINNER;

    // Tokenomics
    uint256 public airdropInterval;
    uint256 public burnInterval;
    uint256 public lotteryInterval;

    uint8 public airdropPercentage;
    uint8 public burnPercentage;
    uint8 public lotteryPercentage;

    uint256 public airdropPool;
    uint256 public burnPool;
    uint256 public lotteryPool;

    uint256 public stakingMinimum;
    uint256 public minimumStakingTime;

    string[] public adminFeeToken;
    mapping(string => uint256) public adminFeeTokenValues;

    mapping(address => uint256) public participantsTotalEntryInUsd;
    mapping(string => uint256) public tokenTotalEntry;
    mapping(address => mapping(string => uint256)) public participantsTokenEntries;

    constructor() {
        owner = msg.sender;
        admin = msg.sender;
        pot_state = POT_STATE.WAITING;
        potDuration = 300;
        minEntranceInUsd = 100;
        percentageFee = 3;
        potCount = 1;
        timeBeforeRefund = 86400;
        PotEntryCount = 0;
        entriesCount = 0;

        // Need to change
        airdropInterval = 300;
        burnInterval = 100;
        lotteryInterval = 200;

        airdropPercentage = 75;
        burnPercentage = 20;
        lotteryPercentage = 5;

        stakingMinimum = 5 * 10**18; // 5 PLSP
        minimumStakingTime = 100 * 24 * 3600; // 100 days

        wethAddr = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        usdtAddr = 0x3B00Ef435fA4FcFF5C209a37d1f3dcff37c705aD;
        uniswapV2FactoryAddr = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        isPriceUpdated = false;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin || msg.sender == owner, 'Only an admin level user can call this function');
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Only owner can call this function');
        _;
    }

    modifier validPLSP() {
        require(PLSP_Address != address(0), 'PLSP Address invalid');
        _;
    }

    event EnteredPot(
        string tokenName,
        address indexed userAddress,
        uint256 indexed potRound,
        uint256 usdValue,
        uint256 amount,
        uint256 indexed enteryCount,
        bool hasEntryInCurrentPot
    );
    event CalculateWinner(
        address indexed winner,
        uint256 indexed potRound,
        uint256 potValue,
        uint256 amount,
        uint256 amountWon,
        uint256 participants
    );

    event PotStateChange(uint256 indexed potRound, POT_STATE indexed potState, uint256 indexed time);

    event TokenSwapFailed(string tokenName);
    event BurnSuccess(uint256 amount);
    event AirdropSuccess(uint256 amount);
    event LotterySuccess(address indexed winner);

    function changeOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function changeAdmin(address _adminAddress) public onlyOwner {
        admin = _adminAddress;
    }

    function setPLSPAddress(address _addrees) public onlyAdmin {
        PLSP_Address = _addrees;
    }

    function setPLSP_Standard(uint256 _amount) public onlyAdmin {
        PLSP_Standard = _amount;
    }

    function addToken(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _tokenAddress,
        uint256 _decimal
    ) public onlyAdmin {
        bool istokenInWhiteList = false;
        tokenWhiteList[_tokenName] = Token(_tokenAddress, _tokenSymbol, _decimal);
        for (uint256 index = 0; index < tokenWhiteListNames.length; index++) {
            if (keccak256(bytes(_tokenName)) == keccak256(bytes(tokenWhiteListNames[index]))) {
                istokenInWhiteList = true;
                tokenWhiteListNames[index] = _tokenName;
            }
        }
        if (!istokenInWhiteList) {
            tokenWhiteListNames.push(_tokenName);
        }
    }

    function removeToken(string memory _tokenName) public onlyAdmin {
        for (uint256 index = 0; index < tokenWhiteListNames.length; index++) {
            if (keccak256(bytes(_tokenName)) == keccak256(bytes(tokenWhiteListNames[index]))) {
                delete tokenWhiteList[_tokenName];
                tokenWhiteListNames[index] = tokenWhiteListNames[tokenWhiteListNames.length - 1];
                tokenWhiteListNames.pop();
            }
        }
    }

    function updateTokenUsdValue(string memory _tokenName, uint256 _valueInUsd) internal tokenInWhiteList(_tokenName) {
        //____change start
        if (keccak256(bytes(_tokenName)) == keccak256(bytes('PLSP'))) {
            tokenLatestPriceFeed[_tokenName] = _valueInUsd < 30 * 10**10 ? 30 * 10**10 : (_valueInUsd * 11) / 10;
        } else {
            tokenLatestPriceFeed[_tokenName] = _valueInUsd;
        }
        //____change end
    }

    //____updateTokenUsdValues function was removed
    //____changePotState function was removed
    //____setMinimumUsdEntranceFee function was removed
    //____setPercentageFee function was removed
    //____setTimeBeforRefund function was removed

    modifier tokenInWhiteList(string memory _tokenName) {
        bool istokenWhiteListed = false;
        for (uint256 index = 0; index < tokenWhiteListNames.length; index++) {
            if (keccak256(bytes(tokenWhiteListNames[index])) == keccak256(bytes(_tokenName))) {
                istokenWhiteListed = true;
            }
        }
        require(istokenWhiteListed, 'Token not supported');
        _;
    }

    function EnterPot(
        string[] memory _tokenNames,
        uint256[] memory _amounts,
        address[] memory _participants
    ) public onlyAdmin {
        if ((potLiveTime + potDuration + 15) <= block.timestamp && (participantCount > 1)) {
            //____added +15 seconds to account for the time it takes calculateWinner() to execute
            calculateWinner();
        }
        for (uint256 __index = 0; __index < _tokenNames.length; __index++) {
            string memory _tokenName = _tokenNames[__index];
            uint256 _amount = _amounts[__index];
            address _participant = _participants[__index];
            _EnterPot(_tokenName, _amount, _participant);
        }
    }

    function _EnterPot(
        string memory _tokenName,
        uint256 _amount,
        address _participant
    ) internal {
        //____change start
        UpdatePrice();
        
        //____change end
        uint256 tokenDecimal = tokenWhiteList[_tokenName].tokenDecimal;

        bool hasEntryInCurrentPot = participantsTotalEntryInUsd[_participant] == 0 ? false : true;
        bool tokenIsInPot = tokenTotalEntry[_tokenName] == 0 ? false : true;
        // bool isPulse = keccak256(bytes(_tokenName)) ==
        //     keccak256(bytes("PULSE"));

        uint256 tokenUsdValue = (tokenLatestPriceFeed[_tokenName] * _amount) / 10**tokenDecimal;

        require(pot_state != POT_STATE.PAUSED, 'Lottery has been paused for maintenance');

        require(tokenUsdValue >= minEntranceInUsd, 'Your entrance amount is less than the minimum entrance');

        participantsTokenEntries[_participant][_tokenName] += _amount;
        participantsTotalEntryInUsd[_participant] += (tokenLatestPriceFeed[_tokenName] * _amount) / 10**tokenDecimal;

        tokenTotalEntry[_tokenName] += _amount;
        if (!hasEntryInCurrentPot) {
            _addToParticipants(_participant);
        }
        if (!tokenIsInPot) {
            tokensInPotNames.push(_tokenName);
        }
        totalPotUsdValue += tokenUsdValue;

        //@optimize
        if (entriesAddress.length == PotEntryCount) {
            entriesAddress.push(_participant);
            entriesUsdValue.push(tokenUsdValue);
        } else {
            entriesAddress[PotEntryCount] = _participant;
            entriesUsdValue[PotEntryCount] = tokenUsdValue;
        }

        if (participantCount == 2 && pot_state != POT_STATE.LIVE) {
            potLiveTime = block.timestamp;
            pot_state = POT_STATE.LIVE;
            emit PotStateChange(potCount, pot_state, potLiveTime);
        }
        if (entriesAddress.length == 1) {
            pot_state = POT_STATE.STARTED;
            potStartTime = block.timestamp;
            emit PotStateChange(potCount, pot_state, potStartTime);
        }
        PotEntryCount++;
        entriesCount++;
        emit EnteredPot(
            _tokenName,
            _participant,
            potCount,
            tokenUsdValue,
            _amount,
            PotEntryCount,
            hasEntryInCurrentPot
        );
    }

    function enterPot(
        string memory _tokenName,
        uint256 _amount,
        address _participant
    ) public payable tokenInWhiteList(_tokenName) {
        if ((potLiveTime + potDuration + 15) <= block.timestamp && (participantCount > 1)) {
            //____added +15 seconds to account for the time it takes calculateWinner() to execute
            calculateWinner();
        }
        //____change start
        
        UpdatePrice();

        //____change end
        uint256 tokenDecimal = tokenWhiteList[_tokenName].tokenDecimal;

        bool hasEntryInCurrentPot = participantsTotalEntryInUsd[_participant] == 0 ? false : true;
        bool tokenIsInPot = tokenTotalEntry[_tokenName] == 0 ? false : true;
        bool isPulse = keccak256(bytes(_tokenName)) == keccak256(bytes('PULSE'));

        uint256 tokenUsdValue = isPulse
            ? (tokenLatestPriceFeed['PULSE'] * _amount) / 10**tokenDecimal
            : (tokenLatestPriceFeed[_tokenName] * _amount) / 10**tokenDecimal;

        require(pot_state != POT_STATE.PAUSED, 'Lottery has been paused for maintenance');

        IPRC20 token = IPRC20(tokenWhiteList[_tokenName].tokenAddress);
        require(tokenUsdValue >= minEntranceInUsd, 'Your entrance amount is less than the minimum entrance');
        if (!isPulse) {
            require(token.transferFrom(_participant, address(this), _amount), 'Unable to charge user');
        }
        //____change start
        else {
            require(msg.value >= _amount, 'Value is less than amount specified');
        }
        //____change end

        participantsTokenEntries[_participant][_tokenName] += _amount;
        participantsTotalEntryInUsd[_participant] += (tokenLatestPriceFeed[_tokenName] * _amount) / 10**tokenDecimal;

        tokenTotalEntry[_tokenName] += _amount;
        if (!hasEntryInCurrentPot) {
            _addToParticipants(_participant);
        }
        if (!tokenIsInPot) {
            tokensInPotNames.push(_tokenName);
        }
        totalPotUsdValue += tokenUsdValue;

        //@optimize
        if (entriesAddress.length == PotEntryCount) {
            entriesAddress.push(_participant);
            entriesUsdValue.push(tokenUsdValue);
        } else {
            entriesAddress[PotEntryCount] = _participant;
            entriesUsdValue[PotEntryCount] = tokenUsdValue;
        }

        if (participantCount == 2 && pot_state != POT_STATE.LIVE) {
            potLiveTime = block.timestamp;
            pot_state = POT_STATE.LIVE;
            emit PotStateChange(potCount, pot_state, potLiveTime);
        }
        if (entriesAddress.length == 1) {
            pot_state = POT_STATE.STARTED;
            potStartTime = block.timestamp;
            emit PotStateChange(potCount, pot_state, potStartTime);
        }
        PotEntryCount++;
        entriesCount++;
        emit EnteredPot(
            _tokenName,
            _participant,
            potCount,
            tokenUsdValue,
            _amount,
            PotEntryCount,
            hasEntryInCurrentPot
        );
        // return true;
    }

    function calculateWinner() public {
        if ((potLiveTime + potDuration) <= block.timestamp && (participantCount > 1)) {
            if (potStartTime == 0) return;

            string memory tokenWithThehighestUsdValue = getPotTokenWithHighestValue();

            address pot_winner = determineWinner();
            uint256 amountToPayAsFees = getAmountToPayAsFees(pot_winner);
            if (amountToPayAsFees > 0) {
                deductAmountToPayAsFees(tokenWithThehighestUsdValue, amountToPayAsFees);
            }

            tokenTotalEntry[tokenWithThehighestUsdValue] =
                tokenTotalEntry[tokenWithThehighestUsdValue] -
                amountToPayAsFees;
            for (uint256 index = 0; index < tokensInPotNames.length; index++) {
                _payAccount(tokensInPotNames[index], pot_winner, tokenTotalEntry[tokensInPotNames[index]]);
            } //Transfer all required tokens to the Pot winner
            LAST_POT_WINNER = pot_winner;
            //____change start
            isPriceUpdated = false;
            //____change end

            emit CalculateWinner(
                pot_winner,
                potCount,
                totalPotUsdValue,
                participantsTotalEntryInUsd[pot_winner],
                (totalPotUsdValue * (100 - percentageFee)) / 100,
                participantCount
            );
            startNewPot();
            //Start the new Pot and set calculating winner to true
            //After winner has been sent the token then set calculating winner to false
        } else {
            return;
        }
    }

    int256 public winningPoint; //to be deleted later
    int256[] public winning_point_during_processing; //this is to be deleted later, it stores the value of the winning point through out the process

    function determineWinner() internal returns (address) {
        uint256 randomNumber = fullFillRandomness();
        winningPoint = int256(randomNumber % totalPotUsdValue);
        int256 winning_point = winningPoint;
        address pot_winner;

        for (uint256 index = 0; index < PotEntryCount; index++) {
            winning_point_during_processing.push(winning_point);
            winning_point -= int256(entriesUsdValue[index]);
            if (winning_point <= 0) {
                //That means that the winner has been found here
                pot_winner = entriesAddress[index];
                break;
            }
        }
        return pot_winner;
    }

    function getRefund() public {
        if (timeBeforeRefund + potStartTime < block.timestamp && participantCount == 1) {
            if (potStartTime == 0) return;
            string memory tokenWithThehighestUsdValue = getPotTokenWithHighestValue();

            uint256 amountToPayAsFees = getAmountToPayAsFees(participants[0]);

            deductAmountToPayAsFees(tokenWithThehighestUsdValue, amountToPayAsFees);

            tokenTotalEntry[tokenWithThehighestUsdValue] =
                tokenTotalEntry[tokenWithThehighestUsdValue] -
                amountToPayAsFees;
            for (uint256 index = 0; index < tokensInPotNames.length; index++) {
                _payAccount(tokensInPotNames[index], participants[0], tokenTotalEntry[tokensInPotNames[index]]);
            }
            startNewPot();
        }
    }

    function deductAmountToPayAsFees(string memory _tokenName, uint256 _value) internal {
        bool tokenInFee = false;
        for (uint256 index = 0; index < adminFeeToken.length; index++) {
            if (keccak256(bytes(_tokenName)) == keccak256(bytes(adminFeeToken[index]))) {
                tokenInFee = true;
            }
        }
        if (!tokenInFee) {
            adminFeeToken.push(_tokenName);
        }
        adminFeeTokenValues[_tokenName] += _value;

        if (keccak256(bytes(_tokenName)) == keccak256(bytes('PLSP'))) {
            _distributeToTokenomicsPools(_value);
        }
    }

    function getAmountToPayAsFees(address _address) internal view returns (uint256) {
        string memory tokenWithThehighestUsdValue = getPotTokenWithHighestValue();
        IPRC20 token = IPRC20(PLSP_Address);
        uint256 userBalance = token.balanceOf(_address);

        uint256 baseFee = (
            (percentageFee * totalPotUsdValue * 10**tokenWhiteList[tokenWithThehighestUsdValue].tokenDecimal) /
                (100 * tokenLatestPriceFeed[tokenWithThehighestUsdValue]) >=
                tokenTotalEntry[tokenWithThehighestUsdValue]
                ? tokenTotalEntry[tokenWithThehighestUsdValue]
                : (percentageFee * totalPotUsdValue * 10**tokenWhiteList[tokenWithThehighestUsdValue].tokenDecimal) /
                    (100 * tokenLatestPriceFeed[tokenWithThehighestUsdValue])
        );
        //____change start
        return
            ((userBalance / PLSP_Standard) >= 1)
                ? baseFee / 2
                : (baseFee - ((userBalance / PLSP_Standard) * baseFee) / 2);
        //____change end
    }

    //____change start
    bool public isPriceUpdated;

    function UpdatePrice() public {
        if(participants.length == 0){
            IUniswapV2Factory factory = IUniswapV2Factory(uniswapV2FactoryAddr);
            for (uint256 index = 0; index < tokenWhiteListNames.length; index++) {
                IUniswapV2Pair pair = IUniswapV2Pair(
                    factory.getPair((tokenWhiteList[tokenWhiteListNames[index]]).tokenAddress, usdtAddr)
                );
                IPRC20 wethToken = IPRC20(pair.token0());

                (uint256 Res0, uint256 Res1, ) = pair.getReserves();
                uint256 res1 = Res1 * (10**wethToken.decimals());
                uint256 price = res1 / Res0;
                updateTokenUsdValue(
                    tokenWhiteListNames[index],
                    (price * 10**10) / (10**(tokenWhiteList[tokenWhiteListNames[index]]).tokenDecimal)
                );
            }
            isPriceUpdated = true;
        }
    }

    //____change end

    function getPotTokenWithHighestValue() internal view returns (string memory) {
        string memory tokenWithThehighestUsdValue = tokensInPotNames[0];
        for (uint256 index = 0; index < tokensInPotNames.length - 1; index++) {
            if (
                tokenTotalEntry[tokensInPotNames[index + 1]] * tokenLatestPriceFeed[tokensInPotNames[index + 1]] >=
                tokenTotalEntry[tokensInPotNames[index]] * tokenLatestPriceFeed[tokensInPotNames[index]]
            ) {
                tokenWithThehighestUsdValue = tokensInPotNames[index + 1];
            }
        }
        return tokenWithThehighestUsdValue;
    }

    function resetPot() public onlyAdmin {
        startNewPot();
    }

    function startNewPot() internal {
        for (uint256 index = 0; index < participantCount; index++) {
            delete participantsTotalEntryInUsd[participants[index]];
            for (uint256 index2 = 0; index2 < tokensInPotNames.length; index2++) {
                delete tokenTotalEntry[tokensInPotNames[index2]];
                delete participantsTokenEntries[participants[index]][tokensInPotNames[index2]];
            }
        }
        //@optimize
        // delete participants;
        participantCount = 0;
        delete tokensInPotNames;
        totalPotUsdValue = 0;

        // @optimize
        // delete entriesAddress;
        // delete entriesUsdValue;
        PotEntryCount = 0;

        pot_state = POT_STATE.WAITING;
        potLiveTime = 0;
        potStartTime = 0;
        potCount++;
    }

    function refundToken(
        string memory _tokenName,
        address _address,
        uint256 _amount
    ) public onlyAdmin {
        _payAccount(_tokenName, _address, _amount);
    }

    function _payAccount(
        string memory _tokenName,
        address _accountToPay,
        uint256 _tokenValue
    ) internal {
        if (_tokenValue <= 0) return;
        if (keccak256(bytes(_tokenName)) == keccak256(bytes('PULSE'))) {
            // payable(_accountToPay).transfer(_tokenValue);
            (bool sent, ) = payable(_accountToPay).call{ value: _tokenValue }('');
            require(sent, 'Failed to send PULSE');
        } else {
            IPRC20 token = IPRC20(tokenWhiteList[_tokenName].tokenAddress);
            require(token.transfer(_accountToPay, _tokenValue), 'Unable to Send Token');
        }
    }

    function fullFillRandomness() public view returns (uint256) {
        uint256 price = getPulsePrice();

        return uint256(uint128(bytes16(keccak256(abi.encodePacked(price, block.difficulty, block.timestamp)))));
    }

    /**
     * @dev add new particiant to particiants list, optimzing gas fee
     */
    function _addToParticipants(address participant) internal {
        if (participantCount == participants.length) {
            participants.push(participant);
        } else {
            participants[participantCount] = participant;
        }

        participantCount++;
    }

    /**
     * @dev Gets current pulse price in comparison with PLS and USDT
     */
    function getPulsePrice() public view returns (uint256 price) {
        IUniswapV2Factory factory = IUniswapV2Factory(uniswapV2FactoryAddr);
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(wethAddr, usdtAddr));
        IPRC20 wethToken = IPRC20(pair.token0());

        (uint256 Res0, uint256 Res1, ) = pair.getReserves();
        uint256 res1 = Res1 * (10**wethToken.decimals());
        price = res1 / Res0;
    }

    /**
     * @dev Swaps accumulated fees into PLS first, and then to PLSP
     */
    function swapAccumulatedFees() external validPLSP nonReentrant {
        require(tokenWhiteListNames.length > 0, 'No whitelisted Tokens');

        IUniswapV2Factory factory = IUniswapV2Factory(uniswapV2FactoryAddr);
        address PLSP_pair = factory.getPair(router.WETH(), PLSP_Address);

        require(PLSP_pair != address(0), 'No pair between PLSP and PLS');

        address[] memory path = new address[](2);

        // Swap each token to PULSE
        for (uint256 i = 0; i < adminFeeToken.length; i++) {
            string storage tokenName = adminFeeToken[i];
            Token storage tokenInfo = tokenWhiteList[tokenName];
            ERC20 token = ERC20(tokenInfo.tokenAddress);
            uint256 balance = adminFeeTokenValues[tokenName];

            if (keccak256(bytes(tokenName)) == keccak256(bytes('PULSE'))) continue;
            if (tokenInfo.tokenAddress == PLSP_Address) continue;

            if (balance > 0) {
                path[0] = tokenInfo.tokenAddress;
                path[1] = router.WETH();

                token.approve(address(router), balance);
                try router.swapExactTokensForETH(balance, 0, path, address(this), block.timestamp) returns (
                    uint256[] memory swappedAmounts
                ) {
                    adminFeeTokenValues[tokenName] -= swappedAmounts[0];
                    adminFeeTokenValues['PULSE'] += swappedAmounts[1];
                } catch Error(
                    string memory /*reason*/
                ) {
                    emit TokenSwapFailed(tokenName);
                } catch (
                    bytes memory /*reason*/
                ) {
                    emit TokenSwapFailed(tokenName);
                }
            }
        }

        // Swap converted pls to plsp
        path[0] = router.WETH();
        path[1] = PLSP_Address;
        uint256 pulseFee = adminFeeTokenValues['PULSE'];
        uint256 amountOutMinForPLSP = router.getAmountsOut(pulseFee, path)[1];

        uint256[] memory amounts = router.swapExactETHForTokens{ value: pulseFee }(
            amountOutMinForPLSP,
            path,
            address(this),
            block.timestamp
        );
        adminFeeTokenValues['PULSE'] -= amounts[0];
        adminFeeTokenValues['PLSP'] += amounts[1];

        _distributeToTokenomicsPools(amounts[1]);
    }

    /**
     * @dev Burns accumulated PLSP fees
     *
     * NOTE can't burn before the burn interval
     */
    function burnAccumulatedPLSP() external validPLSP {
        IPLSP PLSPToken = IPLSP(PLSP_Address);
        uint256 PLSP_Balance = PLSPToken.balanceOf(address(this));

        require(PLSP_Balance > 0, 'No PLSP balance');
        require(burnPool > 0, 'No burn amount');
        require(burnPool <= PLSP_Balance, 'Wrong PLSP Fee Value');

        PLSPToken.performBurn();
        adminFeeTokenValues['PLSP'] -= burnPool;
        burnPool = 0;
        emit BurnSuccess(burnPool);
    }

    /**
     * @dev call for an airdrop on the PLSP token contract
     */
    function airdropAccumulatedPLSP() external validPLSP returns (uint256) {
        IPLSP PLSPToken = IPLSP(PLSP_Address);
        uint256 amount = PLSPToken.performAirdrop();

        airdropPool -= amount;
        adminFeeTokenValues['PLSP'] -= amount;

        emit AirdropSuccess(amount);
        return amount;
    }

    /**
     * @dev call for an airdrop on the PLSP token contract
     */
    function lotteryAccumulatedPLSP() external validPLSP returns (address) {
        IPLSP PLSPToken = IPLSP(PLSP_Address);
        uint256 PLSP_Balance = PLSPToken.balanceOf(address(this));

        require(PLSP_Balance > 0, 'No PLSP balance');
        require(lotteryPool > 0, 'No lottery amount');
        require(lotteryPool <= PLSP_Balance, 'Wrong PLSP Fee Value');

        address winner = PLSPToken.performLottery();
        adminFeeTokenValues['PLSP'] -= lotteryPool;
        lotteryPool = 0;

        emit LotterySuccess(winner);
        return winner;
    }

    /**
     * @dev updates percentages for airdrop, lottery, and burn
     *
     * NOTE The sum of 3 params should be 100, otherwise it reverts
     */
    function setTokenomicsPercentage(
        uint8 _airdrop,
        uint8 _lottery,
        uint8 _burn
    ) external onlyAdmin {
        require(_airdrop + _lottery + _burn == 100, 'Invalid values. Should be 100 in total');

        airdropPercentage = _airdrop;
        lotteryPercentage = _lottery;
        burnPercentage = _burn;
    }

    /**
     * @dev distribute PLSP balance changes to tokenomics pools
     *
     */
    function _distributeToTokenomicsPools(uint256 value) internal {
        uint256 deltaAirdropAmount = (value * airdropPercentage) / 100;
        uint256 deltaLotteryAmount = (value * lotteryPercentage) / 100;
        uint256 deltaBurnAmount = value - deltaAirdropAmount - deltaLotteryAmount;

        airdropPool += deltaAirdropAmount;
        lotteryPool += deltaLotteryAmount;
        burnPool += deltaBurnAmount;
    }

    /**
     * @dev Sets Airdrop interval
     *
     */
    function setAirdropInterval(uint256 interval) external onlyAdmin {
        airdropInterval = interval;
    }

    /**
     * @dev Sets Burn interval
     *
     */
    function setBurnInterval(uint256 interval) external onlyAdmin {
        burnInterval = interval;
    }

    /**
     * @dev Sets Lottery interval
     *
     */
    function setLotteryInterval(uint256 interval) external onlyAdmin {
        lotteryInterval = interval;
    }

    /**
     * @dev Sets minimum PLSP value to get airdrop and lottery
     *
     */
    function setStakingMinimum(uint256 value) external onlyAdmin {
        stakingMinimum = value;
    }

    /**
     * @dev Sets minimum PLSP value to get airdrop and lottery
     *
     */
    function setMinimumStakingTime(uint256 value) external onlyAdmin {
        minimumStakingTime = value;
    }

    /**
     * NOTE: This is just for testing, should be deleted before go live
     */
    function setAdminFeeToken(string calldata tokenName, uint256 value) external {
        adminFeeToken.push(tokenName);
        adminFeeTokenValues[tokenName] += value;
        _distributeToTokenomicsPools(value);
    }

    receive() external payable {
        if (msg.sender == address(router)) return;

        require(
            (tokenLatestPriceFeed['PULSE'] * msg.value) / 10**18 >= minEntranceInUsd,
            'Amount less than required entrance fee'
        );
        enterPot('PULSE', msg.value, msg.sender);
    }

    function sendPulseForTransactionFees() public payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IPRC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface IPLSP {
    error AirdropTimeError();

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function isUserAddress(address addr) external view returns (bool);

    function calculatePairAddress() external view returns (address);

    function performAirdrop() external returns (uint256);

    function performBurn() external returns (uint256);

    function performLottery() external returns (address);

    function setPotContractAddress(address addr) external;

    function setAirdropPercentage(uint8 percentage) external;

    function setAirdropInterval(uint256 interval) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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