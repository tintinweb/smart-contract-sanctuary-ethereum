/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

contract Lottery{
    address private manager;

    struct LotteryTicket{
        address issuedTo;
        uint256 timestamp;
        uint256 lotteryCycle;
    }
    uint256 ticketsCount = 0;
    mapping(uint256 => LotteryTicket) lotteryTicket;

    struct LotteryCycle{
        address winner;
        uint256 winningAmount;
        uint256 startTime;
        uint256 endTime;
    }
    mapping(uint256 => bool) private exists;
    mapping(uint256 => LotteryCycle) private lotteryData;
    mapping(uint256 => uint256 []) private lotteryCycleTickets;

    mapping(address => mapping(uint256 => uint256 [])) private participation;

    modifier onlyManager(){
        require(msg.sender == manager, "Unauthorized call");
        _;
    }

    event LotteryTicketIssued(
        address indexed _to, 
        uint256 indexed _lotterySerialNo,
        uint256 indexed _lotteryTicketNo
    );

    event LotteryEndTimeExtended(
        uint256 indexed _lotterySerialNo,
        uint256 indexed _extendedTime,
        uint256 indexed _newEndTime
    );

    event LotteryWinnerAnnounced(
        address indexed _winnerAddress,
        uint256 indexed _lotteryTicketNo,
        uint256 indexed _lotterySerialNo
    );

    fallback() external payable{}
    receive() external payable{}

    constructor(){
        manager = msg.sender;
    }

    function startLotteryCycle(
        uint256 _lotteryId, 
        uint256 _startInterval, 
        uint256 _endInterval
    ) public onlyManager() {
        require(!exists[_lotteryId], "Lottery already existed");
        lotteryData[_lotteryId].startTime = block.timestamp + _startInterval;
        lotteryData[_lotteryId].endTime = block.timestamp + _startInterval + _endInterval;
    }

    function participateInLottery(uint256 _lotteryId) 
    public payable returns(uint256 lotteryTicket_){
        require(msg.value >=2 ether, "Minimum lottery fee is 2 ETH");
        require(
            (block.timestamp >= lotteryData[_lotteryId].startTime) &&
            (block.timestamp <= lotteryData[_lotteryId].endTime),
            "Lottery is inactive"
        );
        ticketsCount = ticketsCount + 1;
        lotteryTicket[ticketsCount] = LotteryTicket(
            msg.sender, 
            block.timestamp, 
            _lotteryId
        );
        lotteryCycleTickets[_lotteryId].push(ticketsCount);
        participation[msg.sender][_lotteryId].push(ticketsCount);
        lotteryData[_lotteryId].winningAmount += msg.value;
        (bool success, ) = address(this).call{value: msg.value}("");
        require(success, "Participation failed");
        emit LotteryTicketIssued(msg.sender, _lotteryId, ticketsCount);
        return ticketsCount;
    }

    function announceWinner(uint256 _lotteryId, bytes32 randomSeed) 
    public onlyManager()
    returns(uint256 winnerTicket_, address winnerAddress_){
        require(block.timestamp > lotteryData[_lotteryId].endTime, "Lottery not ended");
        uint256 ticketsIssued = lotteryCycleTickets[_lotteryId].length;
        if(ticketsIssued<=3){
            lotteryData[_lotteryId].endTime += (30 minutes);
            emit LotteryEndTimeExtended(
                _lotteryId,
                block.timestamp,
                lotteryData[_lotteryId].endTime
            );
            return(0, address(0));
        }
        uint256 winnerTicket = getLotteryWinner(randomSeed, _lotteryId);
        address winnerAddress = lotteryTicket[winnerTicket].issuedTo;
        emit LotteryWinnerAnnounced(winnerAddress, winnerTicket, _lotteryId);
        return(winnerTicket, winnerAddress);
    }

    function getLotteryWinner(bytes32 randomSeed, uint256 _lotteryId) private view returns(uint256 lotteryTicket_){
        uint256 ticketNo =  uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    msg.sender,
                    randomSeed
                )
            )
        );
        uint256 ticketsIssued = lotteryCycleTickets[_lotteryId].length;
        ticketNo = ticketNo % ticketsIssued;
        ticketNo = lotteryCycleTickets[_lotteryId][ticketNo-1];
        return ticketNo;
    }

    function claimLotteryAmount(uint256 _lotteryId) public{
        require(msg.sender == lotteryData[_lotteryId].winner, "Only winner can claim");
        require(
            address(this).balance >= lotteryData[_lotteryId].winningAmount,
            "Lottery system doesnt have enough ether to claim"
        );
        (bool success,) = address(msg.sender).call{
            value: lotteryData[_lotteryId].winningAmount
        }("");
        require(success, "Claim failed");
    }

}