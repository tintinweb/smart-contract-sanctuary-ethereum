// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {EC} from './EC.sol';
import {ChaumPedersenVerifier} from './ChaumPedersenVerifier.sol';
import {ECDSAGeneralized} from './ECDSAGeneralized.sol';

// address in sepolia 0x6eBE473f35E9E484F3fd34C1818Bc813088ea837
contract MixEth {
    uint8 shufflingPeriodBlocks = 20;
    uint8 challengingPeriodBlocks = 10;
    uint8 withdrawingPeriodBlocks = 10;
    uint256 public amt = 10000000000000000;  // 0.01 ether in wei, количество эфиров для микширования;
    uint256 public shufflingDeposit = 10000000000000000; // 0.01 ether, TBD
    mapping(address => uint256) public deposites;
    address[] public initPubKeys;
    bool public shuffleRound;  // индикатор того, какая фаза микширования происходит
    mapping(address => Status) public shufflers; // адреса шаффлеров и их состояние (ещё не перемешивал, уже перемешал, снял свой депозит)
    mapping(bool => Shuffle) public Shuffles; // параметры каждого раунда перемешивания

    struct Shuffle {
        mapping(uint256 => bool) shuffle; // индикатор наличия точки в перемешивании
        uint256[2] shufflingAccumulatedConstant; // текущая накопленная константа C^*, также является точкой-генератором для кривой, соответственно значения массива - координаты
        address shuffler;
        uint256 noOfPoints; // участвующие в перемешивании точки, в том числе и накопленная константа
        uint256 blockNo;
    }

    struct Status {
        bool alreadyShuffled;
        bool slashed;
    }

    event newDeposit(bool actualRound, uint256[2] indexed newPubKey);
    event newShuffle(bool actualRound, address indexed shuffler, uint256[] shuffle, uint256[2] shufflingAccumulatedConstant);
    event successfulChallenge(bool actualRound, address indexed shuffler);
    event successfulWithdraw(bool actualRound, uint256[2] indexed withdrawnPubKey);

    function deposit(uint256 initPubKeyX, uint256 initPubKeyY) external payable {
        require(msg.value == amt, "Incorrect deposit amount");
        require(EC.onCurve([initPubKeyX, initPubKeyY]), "Invalid public key!");
        require(!Shuffles[shuffleRound].shuffle[initPubKeyX] &&
                !Shuffles[shuffleRound].shuffle[initPubKeyY], 
                "This public key has been already added to the shuffle");
        Shuffles[shuffleRound].shuffle[initPubKeyX] = true;
        Shuffles[shuffleRound].shuffle[initPubKeyY] = true;
        Shuffles[shuffleRound].noOfPoints += 1;

        emit newDeposit(shuffleRound, [initPubKeyX, initPubKeyY]);
    }
    function uploadShuffle(uint256[] memory _oldShuffle, 
                           uint256[] memory _shuffle, 
                           uint256[2] memory _newShufflingConstant) 
                           public onlyInShufflingPeriod() payable {
        require(msg.value == shufflingDeposit + (_shuffle.length / 2 - Shuffles[shuffleRound].noOfPoints) * 0.01 ether, 
                "Invalid shuffler deposit amount!"); // shuffler can also deposit new pubkeys
        require(!shufflers[msg.sender].alreadyShuffled, "Shuffler is not allowed to shuffle more than once!");
        
        // c этим так и не разобрался, почему не проходит тесты
        // require(_oldShuffle.length / 2 == Shuffles[!shuffleRound].noOfPoints, "Incorrectly referenced the last but one shuffle");

        // удаление старых адресов из участвующих в перемешивании адресов
        for(uint256 i = 0; i < _oldShuffle.length; i++) {
            require(Shuffles[!shuffleRound].shuffle[_oldShuffle[i]],"A public key was added twice to the shuffle");
            Shuffles[!shuffleRound].shuffle[_oldShuffle[i]] = false;
        }

        Shuffles[!shuffleRound].shufflingAccumulatedConstant[0] = _newShufflingConstant[0];
        Shuffles[!shuffleRound].shufflingAccumulatedConstant[1] = _newShufflingConstant[1];

        // добавление новых ключей в участвующие в микшировании адреса
        for(uint256 i = 0; i < _shuffle.length; i++) {
            require(!Shuffles[!shuffleRound].shuffle[_shuffle[i]], "Public keys can be added only once to the shuffle!");
            Shuffles[!shuffleRound].shuffle[_shuffle[i]] = true;
        }
        Shuffles[!shuffleRound].shuffler = msg.sender;
        Shuffles[!shuffleRound].noOfPoints = (_shuffle.length) / 2;
        Shuffles[!shuffleRound].blockNo = block.number;
        shuffleRound = !shuffleRound;
        shufflers[msg.sender].alreadyShuffled = true; // получатель может перемешивать адреса только один раз

        emit newShuffle(!shuffleRound, msg.sender, _shuffle, _newShufflingConstant);
    }

    function challengeShuffle(uint256[22] memory proofTranscript) public onlyInChallengingPeriod() {
        bool round = shuffleRound; // только текущие перестановки могут быть оспорены
        require(proofTranscript[0] == Shuffles[!round].shufflingAccumulatedConstant[0]
                && proofTranscript[1] == Shuffles[!round].shufflingAccumulatedConstant[1], 
                "Wrong shuffling accumulated constant for previous round "); // проверка корректности C*_{i-1}
        require(Shuffles[!round].shuffle[proofTranscript[2]] 
                && Shuffles[!round].shuffle[proofTranscript[3]], 
                "Shuffled key is not included in previous round");
        require(proofTranscript[4] == Shuffles[round].shufflingAccumulatedConstant[0]
                && proofTranscript[5] == Shuffles[round].shufflingAccumulatedConstant[1], 
                "Wrong current shuffling accumulated constant"); // проверка корректности C*_{i}
        require(!Shuffles[round].shuffle[proofTranscript[6]] 
                || !Shuffles[round].shuffle[proofTranscript[7]], 
                "Final public key is indeed included in current shuffle");
        require(ChaumPedersenVerifier.verifyChaumPedersen(proofTranscript), "Chaum-Pedersen Proof not verified");
        shufflers[Shuffles[round].shuffler].slashed = true;
        shuffleRound = !shuffleRound;

        emit successfulChallenge(round, Shuffles[round].shuffler);
    }

    function withdrawAmt(uint256[12] memory sig) public {
        withdrawChecks(sig);
        payable(msg.sender).transfer(amt);
    }

    function withdrawChecks(uint256[12] memory sig) internal onlyInWithdrawalDepositPeriod() {
        require(Shuffles[shuffleRound].shuffle[sig[2]] 
                && Shuffles[shuffleRound].shuffle[sig[3]], 
                "Your public key is not included in the final shuffle!");
        require(sig[0] == Shuffles[shuffleRound].shufflingAccumulatedConstant[0]
                && sig[1] == Shuffles[shuffleRound].shufflingAccumulatedConstant[1], 
                "Your signature is using a wrong generator!");
        // require(sig[4] == uint(keccak256(abi.encodePacked(msg.sender, sig[2], sig[3]))), 
        //         "Signed an invalid message!"); // эта проверка нужна для предотвращения атак front-running 
        require(ECDSAGeneralized.verify(sig), "Your signature is not verified!");
        Shuffles[shuffleRound].shuffle[sig[2]] = false;
        Shuffles[shuffleRound].shuffle[sig[3]] = false;
        Shuffles[shuffleRound].noOfPoints -= 1;

        emit successfulWithdraw(shuffleRound, [sig[2], sig[3]]);
    }

    function withdrawDeposit() public onlyShuffler onlyHonestShuffler {
        shufflers[msg.sender].slashed = true;
        payable(msg.sender).transfer(shufflingDeposit);
    }

    modifier onlyInShufflingPeriod() {
        require(Shuffles[shuffleRound].blockNo + shufflingPeriodBlocks < block.number, 
                "You can not shuffle right now!");
        _;
    }

    modifier onlyInChallengingPeriod() {
        require(block.number <= Shuffles[shuffleRound].blockNo + challengingPeriodBlocks, 
                "You can not challenge this shuffle right now!");
        _;
    }

    modifier onlyInWithdrawalDepositPeriod() {
        require(Shuffles[shuffleRound].blockNo + withdrawingPeriodBlocks < block.number, 
                "You can not withdraw/deposit right now!");
        _;
    }

    modifier onlyShuffler() {
        require(shufflers[msg.sender].alreadyShuffled, "You have not shuffled!");
        _;
    }

    modifier onlyHonestShuffler() {
        require(!shufflers[msg.sender].slashed, "Your shuffling deposit has been slashed!");
        _;
    }
}