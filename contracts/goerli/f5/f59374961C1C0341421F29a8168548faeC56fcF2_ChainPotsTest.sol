pragma solidity ^0.8.17;

contract ChainPotsTest {
    address public Admin;
    address private houseAddressOne =
        0xC9Ead2d74ebD92A56f1a14267b5b87eD66885Cee;
    address private houseAddressTwo =
        0xC9Ead2d74ebD92A56f1a14267b5b87eD66885Cee;
    uint256 houseCutOne = 2;
    uint256 houseCutTwo = 2;
    uint256 winnerCut = 96;

    // daily pot

    uint256 public lastDailyPot;
    uint256 public drawTime = 5 minutes;
    address payable[] public playersDailyPot;
    uint256 public dailyPotEntryPrice = 0.001 ether;

    event EntryDailyPot(address indexed _from, uint256 _value);
    event WinnerDailyPot(address indexed _from, uint256 _value);

    // lottery

    address payable[] public playersBronzeLottery;
    uint256 public bronzeLotteryEntryPrice = 0.002 ether;
    uint256 public bronzeLotteryPotMaxAmount = 0.004 ether;
    uint256 public bronzeLotteryMaxEntries = 10;

    address payable[] public playersSilverLottery;
    uint256 public silverLotteryEntryPrice = 0.001 ether;
    uint256 public silverLotteryPotMaxAmount = 0.002 ether;
    uint256 public silverLotteryMaxEntries = 10;

    address payable[] public playersGoldLottery;
    uint256 public goldLotteryEntryPrice = 0.005 ether;
    uint256 public goldLotteryPotMaxAmount = 0.01 ether;
    uint256 public goldLotteryMaxEntries = 10;

    event EntryBronzeLottery(address indexed _from, uint256 _value);
    event WinnerBronzeLottery(address indexed _from, uint256 _value);

    event EntrySilverLottery(address indexed _from, uint256 _value);
    event WinnerSilverLottery(address indexed _from, uint256 _value);

    event EntryGoldLottery(address indexed _from, uint256 _value);
    event WinnerGoldLottery(address indexed _from, uint256 _value);

    // head to head

    address payable[] public playersBronzeHTH;
    uint256 public bronzeHTHEntryPrice = 0.005 ether;
    uint256 public bronzeHTHPotMaxAmount = 0.01 ether;
    uint256 public bronzeHTHMaxEntries = 2;

    address payable[] public playersSilverHTH;
    uint256 public silverHTHEntryPrice = 0.001 ether;
    uint256 public silverHTHPotMaxAmount = 0.002 ether;
    uint256 public silverHTHMaxEntries = 2;

    address payable[] public playersGoldHTH;
    uint256 public goldHTHEntryPrice = 0.005 ether;
    uint256 public goldHTHPotMaxAmount = 0.01 ether;
    uint256 public goldHTHMaxEntries = 2;

    event EntryBronzeHTH(address indexed _from, uint256 _value);
    event WinnerBronzeHTH(address indexed _from, uint256 _value);

    event EntrySilverHTH(address indexed _from, uint256 _value);
    event WinnerSilverHTH(address indexed _from, uint256 _value);

    event EntryGoldHTH(address indexed _from, uint256 _value);
    event WinnerGoldHTH(address indexed _from, uint256 _value);

    constructor() {
        Admin = msg.sender;
    }

    modifier restricted() {
        require(msg.sender == Admin, "You are not the owner");
        _;
    }

    modifier isBronzeLotteryPotFull() {
        require(
            bronzeLotteryMaxEntries == playersBronzeLottery.length,
            "bronzeLottery pot is not full"
        );
        _;
    }

    modifier isSilverLotteryPotFull() {
        require(
            silverLotteryMaxEntries == playersSilverLottery.length,
            "silverLottery pot is not full"
        );
        _;
    }

    modifier isGoldLotteryPotFull() {
        require(
            goldLotteryMaxEntries == playersGoldLottery.length,
            "goldLottery pot is not full"
        );
        _;
    }

    modifier isBronzeHTHPotFull() {
        require(
            bronzeHTHMaxEntries == playersBronzeHTH.length,
            "bronzeHTH pot is not full"
        );
        _;
    }

    modifier isSilverHTHPotFull() {
        require(
            silverHTHMaxEntries == playersSilverHTH.length,
            "silverHTH pot is not full"
        );
        _;
    }

    modifier isGoldHTHPotFull() {
        require(
            goldHTHMaxEntries == playersGoldHTH.length,
            "goldHTH pot is not full"
        );
        _;
    }

    modifier isDailyPotFull() {
        require(
            goldHTHMaxEntries == playersGoldHTH.length,
            "goldHTH pot is not full"
        );
        _;
    }

    /* dailyPot functions */

    function enterDailyPot(uint256 _count) public payable {
        require(
            msg.value == dailyPotEntryPrice * _count,
            "incorrent value sent to contract"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersDailyPot.push(payable(msg.sender));
        }
        emit EntryDailyPot(msg.sender, msg.value);
    }

    function pickDailyPotWinner() external {
        require(
            block.timestamp - lastDailyPot > drawTime,
            "dailyPot timer is still running"
        );
        lastDailyPot = block.timestamp;
        uint256 playersDailyPotLength = playersDailyPot.length;
        uint256 index = randomDailyPot() % playersDailyPotLength;
        address payable winningAddress = playersDailyPot[index];
        uint256 winningAmount = (playersDailyPotLength *
            dailyPotEntryPrice *
            winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddressOne).transfer(
            (playersDailyPotLength * dailyPotEntryPrice * houseCutOne) / 100
        );
        payable(houseAddressTwo).transfer(
            (playersDailyPotLength * dailyPotEntryPrice * houseCutTwo) / 100
        );
        delete playersDailyPot;

        emit WinnerDailyPot(winningAddress, winningAmount);
    }

    function randomDailyPot() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.difficulty,
                        block.timestamp,
                        playersDailyPot
                    )
                )
            );
    }

    function getPlayersDailyPot()
        public
        view
        returns (address payable[] memory)
    {
        return playersDailyPot;
    }

    function setDailyEntryPrice(uint256 _newEntryPrice) external restricted {
        dailyPotEntryPrice = _newEntryPrice;
    }

    /* bronzeLottery functions */

    function enterBronzeLottery(uint256 _count) public payable {
        require(
            msg.value == bronzeLotteryEntryPrice * _count,
            "incorrent value sent to contract"
        );
        require(
            playersBronzeLottery.length + _count <= bronzeLotteryMaxEntries,
            "maximum entries reached"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersBronzeLottery.push(payable(msg.sender));
        }
        if (bronzeLotteryMaxEntries == playersBronzeLottery.length) {
            pickBronzeLotteryWinner();
        }

        emit EntryBronzeLottery(msg.sender, msg.value);
    }

    function pickBronzeLotteryWinner() public isBronzeLotteryPotFull {
        uint256 index = randomBronzeLottery() % playersBronzeLottery.length;
        address payable winningAddress = playersBronzeLottery[index];
        uint256 winningAmount = (bronzeLotteryPotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddressOne).transfer(
            (bronzeLotteryPotMaxAmount * houseCutOne) / 100
        );
        payable(houseAddressTwo).transfer(
            (bronzeLotteryPotMaxAmount * houseCutTwo) / 100
        );
        delete playersBronzeLottery;

        emit WinnerBronzeLottery(winningAddress, winningAmount);
    }

    function setBronzeLotteryEntryPrice(uint256 _newEntryPrice)
        external
        restricted
    {
        bronzeLotteryEntryPrice = _newEntryPrice;
    }

    function setBronzeLotteryMaxEntries(uint256 _newMaxEntries)
        external
        restricted
    {
        bronzeLotteryMaxEntries = _newMaxEntries;
    }

    function randomBronzeLottery() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.difficulty,
                        block.timestamp,
                        playersBronzeLottery
                    )
                )
            );
    }

    function getPlayersBronzeLottery()
        public
        view
        returns (address payable[] memory)
    {
        return playersBronzeLottery;
    }

    /* silverLottery functions */

    function enterSilverLottery(uint256 _count) public payable {
        require(
            msg.value == silverLotteryEntryPrice * _count,
            "incorrent value sent to contract"
        );
        require(
            playersSilverLottery.length + _count <= silverLotteryMaxEntries,
            "maximum entries reached"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersSilverLottery.push(payable(msg.sender));
        }
        if (silverLotteryMaxEntries == playersSilverLottery.length) {
            pickSilverLotteryWinner();
        }

        emit EntrySilverLottery(msg.sender, msg.value);
    }

    function pickSilverLotteryWinner() public isSilverLotteryPotFull {
        uint256 index = randomSilverLottery() % playersSilverLottery.length;
        address payable winningAddress = playersSilverLottery[index];
        uint256 winningAmount = (silverLotteryPotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddressOne).transfer(
            (silverLotteryPotMaxAmount * houseCutOne) / 100
        );
        payable(houseAddressTwo).transfer(
            (silverLotteryPotMaxAmount * houseCutTwo) / 100
        );
        delete playersSilverLottery;

        emit WinnerSilverLottery(winningAddress, winningAmount);
    }

    function setSilverLotteryEntryPrice(uint256 _newEntryPrice)
        external
        restricted
    {
        silverLotteryEntryPrice = _newEntryPrice;
    }

    function setSilverLotteryMaxEntries(uint256 _newMaxEntries)
        external
        restricted
    {
        silverLotteryMaxEntries = _newMaxEntries;
    }

    function randomSilverLottery() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.difficulty,
                        block.timestamp,
                        playersSilverLottery
                    )
                )
            );
    }

    function getPlayersSilverLottery()
        public
        view
        returns (address payable[] memory)
    {
        return playersSilverLottery;
    }

    /* goldLottery functions */

    function enterGoldLottery(uint256 _count) public payable {
        require(
            msg.value == goldLotteryEntryPrice * _count,
            "incorrent value sent to contract"
        );
        require(
            playersGoldLottery.length + _count <= goldLotteryMaxEntries,
            "maximum entries reached"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersGoldLottery.push(payable(msg.sender));
        }
        if (goldLotteryMaxEntries == playersGoldLottery.length) {
            pickGoldLotteryWinner();
        }

        emit EntryGoldLottery(msg.sender, msg.value);
    }

    function pickGoldLotteryWinner() public isGoldLotteryPotFull {
        uint256 index = randomGoldLottery() % playersGoldLottery.length;
        address payable winningAddress = playersGoldLottery[index];
        uint256 winningAmount = (goldLotteryPotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddressOne).transfer(
            (goldLotteryPotMaxAmount * houseCutOne) / 100
        );
        payable(houseAddressTwo).transfer(
            (goldLotteryPotMaxAmount * houseCutTwo) / 100
        );
        delete playersGoldLottery;

        emit WinnerGoldLottery(winningAddress, winningAmount);
    }

    function setGoldLotteryEntryPrice(uint256 _newEntryPrice)
        external
        restricted
    {
        goldLotteryEntryPrice = _newEntryPrice;
    }

    function setGoldLotteryMaxEntries(uint256 _newMaxEntries)
        external
        restricted
    {
        goldLotteryMaxEntries = _newMaxEntries;
    }

    function randomGoldLottery() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.difficulty,
                        block.timestamp,
                        playersGoldLottery
                    )
                )
            );
    }

    function getPlayersGoldLottery()
        public
        view
        returns (address payable[] memory)
    {
        return playersGoldLottery;
    }

    /* bronzeHTH functions */

    function enterBronzeHTH(uint256 _count) public payable {
        require(
            msg.value == bronzeHTHEntryPrice * _count,
            "incorrent value sent to contract"
        );
        require(
            playersBronzeHTH.length + _count <= bronzeHTHMaxEntries,
            "maximum entries reached"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersBronzeHTH.push(payable(msg.sender));
        }
        if (bronzeHTHMaxEntries == playersBronzeHTH.length) {
            pickBronzeHTHWinner();
        }

        emit EntryBronzeHTH(msg.sender, msg.value);
    }

    function pickBronzeHTHWinner() public isBronzeHTHPotFull {
        uint256 index = randomBronzeHTH() % playersBronzeHTH.length;
        address payable winningAddress = playersBronzeHTH[index];
        uint256 winningAmount = (bronzeHTHPotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddressOne).transfer(
            (bronzeHTHPotMaxAmount * houseCutOne) / 100
        );
        payable(houseAddressTwo).transfer(
            (bronzeHTHPotMaxAmount * houseCutTwo) / 100
        );
        delete playersBronzeHTH;

        emit WinnerBronzeHTH(winningAddress, winningAmount);
    }

    function setBronzeHTHEntryPrice(uint256 _newEntryPrice)
        external
        restricted
    {
        bronzeHTHEntryPrice = _newEntryPrice;
    }

    function setBronzeHTHMaxEntries(uint256 _newMaxEntries)
        external
        restricted
    {
        bronzeHTHMaxEntries = _newMaxEntries;
    }

    function randomBronzeHTH() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.difficulty,
                        block.timestamp,
                        playersBronzeHTH
                    )
                )
            );
    }

    function getPlayersBronzeHTH()
        public
        view
        returns (address payable[] memory)
    {
        return playersBronzeHTH;
    }

    /* silverHTH functions */

    function enterSilverHTH(uint256 _count) public payable {
        require(
            msg.value == silverHTHEntryPrice * _count,
            "incorrent value sent to contract"
        );
        require(
            playersSilverHTH.length + _count <= silverHTHMaxEntries,
            "maximum entries reached"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersSilverHTH.push(payable(msg.sender));
        }
        if (silverHTHMaxEntries == playersSilverHTH.length) {
            pickSilverHTHWinner();
        }

        emit EntrySilverHTH(msg.sender, msg.value);
    }

    function pickSilverHTHWinner() public isSilverHTHPotFull {
        uint256 index = randomSilverHTH() % playersSilverHTH.length;
        address payable winningAddress = playersSilverHTH[index];
        uint256 winningAmount = (silverHTHPotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddressOne).transfer(
            (silverHTHPotMaxAmount * houseCutOne) / 100
        );
        payable(houseAddressTwo).transfer(
            (silverHTHPotMaxAmount * houseCutTwo) / 100
        );
        delete playersSilverHTH;

        emit WinnerSilverHTH(winningAddress, winningAmount);
    }

    function setSilverHTHEntryPrice(uint256 _newEntryPrice)
        external
        restricted
    {
        silverHTHEntryPrice = _newEntryPrice;
    }

    function setSilverHTHMaxEntries(uint256 _newMaxEntries)
        external
        restricted
    {
        silverHTHMaxEntries = _newMaxEntries;
    }

    function randomSilverHTH() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.difficulty,
                        block.timestamp,
                        playersSilverHTH
                    )
                )
            );
    }

    function getPlayersSilverHTH()
        public
        view
        returns (address payable[] memory)
    {
        return playersSilverHTH;
    }

    /* goldHTH functions */

    function enterGoldHTH(uint256 _count) public payable {
        require(
            msg.value == goldHTHEntryPrice * _count,
            "incorrent value sent to contract"
        );
        require(
            playersGoldHTH.length + _count <= goldHTHMaxEntries,
            "maximum entries reached"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersGoldHTH.push(payable(msg.sender));
        }
        if (goldHTHMaxEntries == playersGoldHTH.length) {
            pickGoldHTHWinner();
        }

        emit EntryGoldHTH(msg.sender, msg.value);
    }

    function pickGoldHTHWinner() public isGoldHTHPotFull {
        uint256 index = randomGoldHTH() % playersGoldHTH.length;
        address payable winningAddress = playersGoldHTH[index];
        uint256 winningAmount = (goldHTHPotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddressOne).transfer(
            (goldHTHPotMaxAmount * houseCutOne) / 100
        );
        payable(houseAddressTwo).transfer(
            (goldHTHPotMaxAmount * houseCutTwo) / 100
        );
        delete playersGoldHTH;

        emit WinnerGoldHTH(winningAddress, winningAmount);
    }

    function setGoldHTHEntryPrice(uint256 _newEntryPrice) external restricted {
        goldHTHEntryPrice = _newEntryPrice;
    }

    function setGoldHTHMaxEntries(uint256 _newMaxEntries) external restricted {
        goldHTHMaxEntries = _newMaxEntries;
    }

    function randomGoldHTH() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.difficulty,
                        block.timestamp,
                        playersGoldHTH
                    )
                )
            );
    }

    function getPlayersGoldHTH()
        public
        view
        returns (address payable[] memory)
    {
        return playersGoldHTH;
    }

    /* admin functions */

    function setWinnerCut(uint256 _newWinnerCut) external restricted {
        winnerCut = _newWinnerCut;
    }

    function setHouseOneCut(uint256 _newHouseCut) external restricted {
        houseCutOne = _newHouseCut;
    }

    function setHouseTwoCut(uint256 _newHouseCut) external restricted {
        houseCutTwo = _newHouseCut;
    }

    function setHouseAddressOne(address _newAddress) external restricted {
        houseAddressOne = _newAddress;
    }

    function setHouseAddressTwo(address _newAddress) external restricted {
        houseAddressTwo = _newAddress;
    }

    function setDrawTime(uint256 _newDrawTime) external restricted {
        drawTime = _newDrawTime;
    }

    function withdrawFallback() external payable restricted {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}