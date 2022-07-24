/**
 *Submitted for verification at Etherscan.io on 2022-04-18
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./IPRC20.sol";
import "./PLSP.sol";

// File: PotContract.sol

contract PotLottery {
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

    struct TokenSwapError {
        string tokenName;
        string reason;
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
    address public addressToRecieveFee;

    // This is for Rinkeby
    address public wethAddr = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address public usdtAddr = 0x3B00Ef435fA4FcFF5C209a37d1f3dcff37c705aD;
    address public uniswapV2FactoryAddr =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    IUniswapV2Router02 public router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

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
    address[] public participants;
    string[] public tokensInPotNames;
    uint256 public totalPotUsdValue;
    address[] public entriesAddress;
    uint256[] public entriesUsdValue;
    address public LAST_POT_WINNER;

    string[] public adminFeeToken;
    mapping(string => uint256) public adminFeeTokenValues;

    mapping(address => uint256) public participantsTotalEntryInUsd;
    mapping(string => uint256) public tokenTotalEntry;
    mapping(address => mapping(string => uint256))
        public participantsTokenEntries;

    constructor(address _owner) {
        owner = _owner;
        admin = _owner;
        addressToRecieveFee = _owner;
        pot_state = POT_STATE.WAITING;
        potDuration = 3600;
        minEntranceInUsd = 100;
        percentageFee = 1;
        potCount = 1;
        timeBeforeRefund = 86400;
        PotEntryCount = 0;
        entriesCount = 0;
    }

    modifier onlyAdmin() {
        require(
            msg.sender == admin || msg.sender == owner,
            "Only an admin level user can call this function"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier validPLSP() {
        require(PLSP_Address != address(0), "PLSP Address invalid");
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

    event PotStateChange(
        uint256 indexed potRound,
        POT_STATE indexed potState,
        uint256 indexed time
    );

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
        tokenWhiteList[_tokenName] = Token(
            _tokenAddress,
            _tokenSymbol,
            _decimal
        );
        for (uint256 index = 0; index < tokenWhiteListNames.length; index++) {
            if (
                keccak256(bytes(_tokenName)) ==
                keccak256(bytes(tokenWhiteListNames[index]))
            ) {
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
            if (
                keccak256(bytes(_tokenName)) ==
                keccak256(bytes(tokenWhiteListNames[index]))
            ) {
                delete tokenWhiteList[_tokenName];
                tokenWhiteListNames[index] = tokenWhiteListNames[
                    tokenWhiteListNames.length - 1
                ];
                tokenWhiteListNames.pop();
            }
        }
    }

    function updateTokenUsdValue(string memory _tokenName, uint256 _valueInUsd)
        public
        onlyAdmin
        tokenInWhiteList(_tokenName)
    {
        tokenLatestPriceFeed[_tokenName] = _valueInUsd;
    }

    function updateTokenUsdValues(
        string[] memory _tokenNames,
        uint256[] memory _valuesInUsd
    ) public onlyAdmin {
        require(
            _tokenNames.length == _valuesInUsd.length,
            "No of address is not equal to number of usd values"
        );
        for (uint256 index = 0; index < _tokenNames.length; index++) {
            updateTokenUsdValue(_tokenNames[index], _valuesInUsd[index]);
        }
    }

    function changePotState(POT_STATE _potState) public onlyAdmin {
        pot_state = _potState;
    }

    function setMinimumUsdEntranceFee(uint256 _minimumUsdEntrance)
        public
        onlyAdmin
    {
        minEntranceInUsd = _minimumUsdEntrance;
    }

    function setPercentageFee(uint256 _percentageFee) public onlyAdmin {
        percentageFee = _percentageFee;
    }

    function setPotDuration(uint256 _potDuration) public onlyAdmin {
        potDuration = _potDuration;
    }

    function setAddressToRecieveFee(address _addressToRecieveFee)
        public
        onlyAdmin
    {
        addressToRecieveFee = _addressToRecieveFee;
    }

    function setTimeBeforRefund(uint256 _timeBeforeRefund) public onlyAdmin {
        timeBeforeRefund = _timeBeforeRefund;
    }

    modifier tokenInWhiteList(string memory _tokenName) {
        bool istokenWhiteListed = false;
        for (uint256 index = 0; index < tokenWhiteListNames.length; index++) {
            if (
                keccak256(bytes(tokenWhiteListNames[index])) ==
                keccak256(bytes(_tokenName))
            ) {
                istokenWhiteListed = true;
            }
        }
        require(istokenWhiteListed, "Token not supported");
        _;
    }

    function EnterPot(
        string[] memory _tokenNames,
        uint256[] memory _amounts,
        address[] memory _participants
    ) public onlyAdmin {
        if (
            (potLiveTime + potDuration) <= block.timestamp &&
            (participants.length > 1)
        ) {
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
    ) private {
        uint256 tokenDecimal = tokenWhiteList[_tokenName].tokenDecimal;

        bool hasEntryInCurrentPot = participantsTotalEntryInUsd[_participant] ==
            0
            ? false
            : true;
        bool tokenIsInPot = tokenTotalEntry[_tokenName] == 0 ? false : true;
        // bool isPulse = keccak256(bytes(_tokenName)) ==
        //     keccak256(bytes("PULSE"));

        uint256 tokenUsdValue = (tokenLatestPriceFeed[_tokenName] * _amount) /
            10**tokenDecimal;

        require(
            pot_state != POT_STATE.PAUSED,
            "Lottery has been paused for maintenance"
        );

        require(
            tokenUsdValue >= minEntranceInUsd,
            "Your entrance amount is less than the minimum entrance"
        );

        participantsTokenEntries[_participant][_tokenName] += _amount;
        participantsTotalEntryInUsd[_participant] +=
            (tokenLatestPriceFeed[_tokenName] * _amount) /
            10**tokenDecimal;

        tokenTotalEntry[_tokenName] += _amount;
        if (!hasEntryInCurrentPot) {
            participants.push(_participant);
        }
        if (!tokenIsInPot) {
            tokensInPotNames.push(_tokenName);
        }
        totalPotUsdValue += tokenUsdValue;
        entriesAddress.push(_participant);
        entriesUsdValue.push(tokenUsdValue);
        if (participants.length == 2 && pot_state != POT_STATE.LIVE) {
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
    ) public tokenInWhiteList(_tokenName) {
        if (
            (potLiveTime + potDuration) <= block.timestamp &&
            (participants.length > 1)
        ) {
            calculateWinner();
        }
        uint256 tokenDecimal = tokenWhiteList[_tokenName].tokenDecimal;

        bool hasEntryInCurrentPot = participantsTotalEntryInUsd[_participant] ==
            0
            ? false
            : true;
        bool tokenIsInPot = tokenTotalEntry[_tokenName] == 0 ? false : true;
        bool isPulse = keccak256(bytes(_tokenName)) ==
            keccak256(bytes("PULSE"));

        uint256 tokenUsdValue = isPulse
            ? (tokenLatestPriceFeed["PULSE"] * _amount) / 10**tokenDecimal
            : (tokenLatestPriceFeed[_tokenName] * _amount) / 10**tokenDecimal;

        require(
            pot_state != POT_STATE.PAUSED,
            "Lottery has been paused for maintenance"
        );

        IPRC20 token = IPRC20(tokenWhiteList[_tokenName].tokenAddress);
        require(
            tokenUsdValue >= minEntranceInUsd,
            "Your entrance amount is less than the minimum entrance"
        );
        if (!isPulse) {
            require(
                token.transferFrom(_participant, address(this), _amount),
                "Unable to charge user"
            );
        }

        participantsTokenEntries[_participant][_tokenName] += _amount;
        participantsTotalEntryInUsd[_participant] +=
            (tokenLatestPriceFeed[_tokenName] * _amount) /
            10**tokenDecimal;

        tokenTotalEntry[_tokenName] += _amount;
        if (!hasEntryInCurrentPot) {
            participants.push(_participant);
        }
        if (!tokenIsInPot) {
            tokensInPotNames.push(_tokenName);
        }
        totalPotUsdValue += tokenUsdValue;
        entriesAddress.push(_participant);
        entriesUsdValue.push(tokenUsdValue);
        if (participants.length == 2 && pot_state != POT_STATE.LIVE) {
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
        if (
            (potLiveTime + potDuration) <= block.timestamp &&
            (participants.length > 1)
        ) {
            if (potStartTime == 0) return;

            string
                memory tokenWithThehighestUsdValue = getPotTokenWithHighestValue();

            address pot_winner = determineWinner();
            uint256 amountToPayAsFees = getAmountToPayAsFees(pot_winner);
            if (amountToPayAsFees > 0) {
                deductAmountToPayAsFees(
                    tokenWithThehighestUsdValue,
                    amountToPayAsFees
                );
            }

            tokenTotalEntry[tokenWithThehighestUsdValue] =
                tokenTotalEntry[tokenWithThehighestUsdValue] -
                amountToPayAsFees;
            for (uint256 index = 0; index < tokensInPotNames.length; index++) {
                payAccount(
                    tokensInPotNames[index],
                    pot_winner,
                    tokenTotalEntry[tokensInPotNames[index]]
                );
            } //Transfer all required tokens to the Pot winner
            LAST_POT_WINNER = pot_winner;

            emit CalculateWinner(
                pot_winner,
                potCount,
                totalPotUsdValue,
                participantsTotalEntryInUsd[pot_winner],
                (totalPotUsdValue * (100 - percentageFee)) / 100,
                participants.length
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

    function determineWinner() private returns (address) {
        uint256 randomNumber = fullFillRandomness();
        winningPoint = int256(randomNumber % totalPotUsdValue);
        int256 winning_point = winningPoint;
        address pot_winner;

        for (uint256 index = 0; index < entriesAddress.length; index++) {
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
        if (
            timeBeforeRefund + potStartTime < block.timestamp &&
            participants.length == 1
        ) {
            if (potStartTime == 0) return;
            string
                memory tokenWithThehighestUsdValue = getPotTokenWithHighestValue();

            uint256 amountToPayAsFees = getAmountToPayAsFees(participants[0]);

            deductAmountToPayAsFees(
                tokenWithThehighestUsdValue,
                amountToPayAsFees
            );

            tokenTotalEntry[tokenWithThehighestUsdValue] =
                tokenTotalEntry[tokenWithThehighestUsdValue] -
                amountToPayAsFees;
            for (uint256 index = 0; index < tokensInPotNames.length; index++) {
                payAccount(
                    tokensInPotNames[index],
                    participants[0],
                    tokenTotalEntry[tokensInPotNames[index]]
                );
            }
            startNewPot();
        }
    }

    function deductAmountToPayAsFees(string memory _tokenName, uint256 _value)
        private
    {
        bool tokenInFee = false;
        for (uint256 index = 0; index < adminFeeToken.length; index++) {
            if (
                keccak256(bytes(_tokenName)) ==
                keccak256(bytes(adminFeeToken[index]))
            ) {
                tokenInFee = true;
            }
        }
        if (!tokenInFee) {
            adminFeeToken.push(_tokenName);
        }
        adminFeeTokenValues[_tokenName] += _value;
    }

    function removeAccumulatedFees() public onlyAdmin {
        for (uint256 index = 0; index < adminFeeToken.length; index++) {
            payAccount(
                adminFeeToken[index],
                addressToRecieveFee,
                adminFeeTokenValues[adminFeeToken[index]]
            );
            delete adminFeeTokenValues[adminFeeToken[index]];
        }
        delete adminFeeToken;
    }

    function getAmountToPayAsFees(address _address)
        private
        view
        returns (uint256)
    {
        string
            memory tokenWithThehighestUsdValue = getPotTokenWithHighestValue();
        IPRC20 token = IPRC20(PLSP_Address);
        uint256 userBalance = token.balanceOf(_address);

        uint256 baseFee = (
            (percentageFee *
                totalPotUsdValue *
                10**tokenWhiteList[tokenWithThehighestUsdValue].tokenDecimal) /
                (100 * tokenLatestPriceFeed[tokenWithThehighestUsdValue]) >=
                tokenTotalEntry[tokenWithThehighestUsdValue]
                ? tokenTotalEntry[tokenWithThehighestUsdValue]
                : (percentageFee *
                    totalPotUsdValue *
                    10 **
                        tokenWhiteList[tokenWithThehighestUsdValue]
                            .tokenDecimal) /
                    (100 * tokenLatestPriceFeed[tokenWithThehighestUsdValue])
        );

        return
            ((userBalance / PLSP_Standard) >= 1)
                ? 0
                : (baseFee - ((userBalance / PLSP_Standard) * baseFee));
    }

    function getPotTokenWithHighestValue()
        private
        view
        returns (string memory)
    {
        string memory tokenWithThehighestUsdValue = tokensInPotNames[0];
        for (uint256 index = 0; index < tokensInPotNames.length - 1; index++) {
            if (
                tokenTotalEntry[tokensInPotNames[index + 1]] *
                    tokenLatestPriceFeed[tokensInPotNames[index + 1]] >=
                tokenTotalEntry[tokensInPotNames[index]] *
                    tokenLatestPriceFeed[tokensInPotNames[index]]
            ) {
                tokenWithThehighestUsdValue = tokensInPotNames[index + 1];
            }
        }
        return tokenWithThehighestUsdValue;
    }

    function resetPot() public onlyAdmin {
        startNewPot();
    }

    function startNewPot() private {
        for (uint256 index = 0; index < participants.length; index++) {
            delete participantsTotalEntryInUsd[participants[index]];
            for (
                uint256 index2 = 0;
                index2 < tokensInPotNames.length;
                index2++
            ) {
                delete tokenTotalEntry[tokensInPotNames[index2]];
                delete participantsTokenEntries[participants[index]][
                    tokensInPotNames[index2]
                ];
            }
        }
        delete participants;
        delete tokensInPotNames;
        totalPotUsdValue = 0;
        delete entriesAddress;
        delete entriesUsdValue;
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
        payAccount(_tokenName, _address, _amount);
    }

    function payAccount(
        string memory _tokenName,
        address _accountToPay,
        uint256 _tokenValue
    ) public {
        if (_tokenValue <= 0) return;
        if (keccak256(bytes(_tokenName)) == keccak256(bytes("PULSE"))) {
            // payable(_accountToPay).transfer(_tokenValue);
            (bool sent, ) = _accountToPay.call{value: _tokenValue}("");
            require(sent, "Failed to send PULSE");
        } else {
            IPRC20 token = IPRC20(tokenWhiteList[_tokenName].tokenAddress);
            require(
                token.transfer(_accountToPay, _tokenValue),
                "Unable to Send Token"
            );
        }
    }

    function fullFillRandomness() public view returns (uint256) {
        uint256 price = getPulsePrice();

        return
            uint256(
                uint128(
                    bytes16(
                        keccak256(
                            abi.encodePacked(
                                price,
                                block.difficulty,
                                block.timestamp
                            )
                        )
                    )
                )
            );
    }

    function getPulsePrice() public view returns (uint256 price) {
        IUniswapV2Factory factory = IUniswapV2Factory(uniswapV2FactoryAddr);
        IUniswapV2Pair pair = IUniswapV2Pair(
            factory.getPair(wethAddr, usdtAddr)
        );
        IPRC20 wethToken = IPRC20(pair.token0());
        (uint256 Res0, uint256 Res1, ) = pair.getReserves();
        uint256 res1 = Res1 * (10**wethToken.decimals());
        price = res1 / Res0;
    }

    function swapAccumulatedFees() external validPLSP {
        require(tokenWhiteListNames.length > 0, "No whitelisted Tokens");

        address[] memory path = new address[](2);

        // Swap each token to pls
        for (uint256 i = 0; i < tokenWhiteListNames.length; i++) {
            string storage tokenName = tokenWhiteListNames[i];
            Token storage tokenInfo = tokenWhiteList[tokenName];
            ERC20 token = ERC20(tokenInfo.tokenAddress);
            uint256 balance = token.balanceOf(address(this));

            if (balance > 0) {
                path[0] = tokenInfo.tokenAddress;
                path[1] = router.WETH();

                token.approve(address(router), balance);
                router.swapExactTokensForETH(
                    balance,
                    0,
                    path,
                    address(this),
                    block.timestamp * 2
                );
            }
        }

        // Swap converted pls to plsp
        path[0] = router.WETH();
        path[1] = PLSP_Address;
        uint256 contractBalance = address(this).balance;
        uint256 amountOutMinForPLSP = router.getAmountsOut(
            contractBalance,
            path
        )[1];

        router.swapExactETHForTokens{value: contractBalance}(
            amountOutMinForPLSP,
            path,
            address(this),
            block.timestamp
        );
    }

    function burnAccumulatedPSLP() external onlyAdmin validPLSP {
        PLSP PLSPToken = PLSP(PLSP_Address);
        uint256 PLSP_balance = PLSPToken.balanceOf(address(this));

        require(PLSP_balance > 0, "No PLSP balance");

        PLSPToken.burn(PLSP_balance);
    }

    receive() external payable {
        if (msg.sender == address(router)) return;

        require(
            (tokenLatestPriceFeed["PULSE"] * msg.value) / 10**18 >=
                minEntranceInUsd,
            "Amount less than required entrance fee"
        );
        enterPot("PULSE", msg.value, msg.sender);
    }

    function sendPulseForTransactionFees() public payable {}
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PLSP is ERC20, Ownable {
    using SafeMath for uint256;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000 * 10**18);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}

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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
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

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

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