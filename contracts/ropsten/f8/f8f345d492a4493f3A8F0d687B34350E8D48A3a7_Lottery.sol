/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier:Unlicensed

library SafeMathAssembly {

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        assembly {
            c := add(a,b)
        }
        require(c >= a, "SafeMath: addition overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a, "SafeMath subraction overFloe");
        assembly {
            c := sub(a,b)
        }
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        assembly {
            c := mul(a,b)
        }
        require(c / a == b, "SafeMath: multiplication overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0,  "SafeMath: division by zero");
        assembly {
            c := div(a,b)
        }
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256 res) {
        require(b != 0, "SafeMath: modulo by zero");
        assembly {
            res := mod(a,b)
        }
    }

}

interface IERC20 {
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view returns(address){
        return(msg.sender);
    }

    function _msgData() internal pure returns(bytes memory){
        return(msg.data);
    }
}

abstract contract Ownable is Context {

    address private _owner;

    constructor(){
        _owner = _msgSender();
    }

    modifier onlyOwner(){
        require(_msgSender() == _owner, "NOT AN OWNER");
        _;
    }

    function owner() public view returns(address){
        return _owner;
    }
}

contract Lottery is Ownable{

    using SafeMathAssembly for uint256;

    uint256 public numPoolId;
    uint256 private startingTicketNumber = 999;
    address public GRATToken;

    struct poolDetail{
        uint startTime;
        uint endTime;
        uint ticketPrice;
        uint totalTicketInSupply;
        uint totalAmountReceived;
        uint[] allTickets;
        bool status;
        uint[] prizeTickets;
    }

    mapping(address => mapping(uint => uint[])) public userTicketInfo;
    mapping(uint => poolDetail) public poolDetails;

    constructor(address _GRATToken){
        GRATToken = _GRATToken;
    }

    function startLottery(uint _startTime, uint _poolId, uint _ticketAmount) external onlyOwner{
        require(_startTime > block.timestamp, "CONFUSION IN START TIME");
        require(_poolId > 0 && _poolId > numPoolId,"ENTERING WRONG POOL ID");

        poolDetail storage PoolDetails = poolDetails[_poolId];
        PoolDetails.startTime = _startTime;
        PoolDetails.ticketPrice = _ticketAmount;

        numPoolId++;
    }

    function buyTickets(uint _poolId, uint _numberTickets, uint _numTokens) external {
        require(_poolId > 0 && _poolId <= numPoolId,"ENTERING WRONG POOL ID");
        require(_numTokens == ticketPrice(_poolId,_numberTickets), "WRONG TICKET AMOUNT");
        require(!poolDetails[_poolId].status, "LOTTERY STOPPED");

        IERC20(GRATToken).transferFrom(_msgSender(), address(this), _numTokens);

        poolDetail storage PoolDetails = poolDetails[_poolId];
        PoolDetails.totalTicketInSupply = PoolDetails.totalTicketInSupply.add(_numberTickets);
        PoolDetails.totalAmountReceived = PoolDetails.totalAmountReceived.add(_numTokens);

        pushLotteryTickets(_poolId,_numberTickets);
    }

    function endLottery(uint _poolId) external onlyOwner {
        require(_poolId > 0 && _poolId <= numPoolId, "INVALID POOL ID");
        require(!poolDetails[_poolId].status,"ALREADY ENDED");
        require(poolDetails[_poolId].startTime < block.timestamp, "LOTTERY IS NOT STARTED");

        poolDetail storage PoolDetails = poolDetails[_poolId];
        PoolDetails.status = true;
        fetchWinner(_poolId);
    }

    function ticketPrice(uint _poolId, uint _numTickets) public view returns(uint totalAmount){
        require(_poolId > 0 && _poolId <= numPoolId,"ENTERING WRONG POOL ID");
        uint ticketAmount = poolDetails[_poolId].ticketPrice;
        totalAmount = ticketAmount.mul(_numTickets);
    }

    function pushLotteryTickets(uint _poolId, uint _numberTickets) private {
        uint[] memory ticketNumbers = generateLotteryTicket(_numberTickets);
        poolDetail storage PoolDetails = poolDetails[_poolId];
        for(uint i=0; i<_numberTickets; i++){
            userTicketInfo[_msgSender()][_poolId].push(ticketNumbers[i]);
            PoolDetails.allTickets.push(ticketNumbers[i]);
        }
    }

    function generateLotteryTicket(uint _numTickets) private returns(uint[] memory ticketNumber){
        ticketNumber = new uint[](_numTickets);
        for(uint i=0; i < _numTickets; i++){
            startingTicketNumber++;
            ticketNumber[i] = startingTicketNumber;
        }
        return ticketNumber;
    }

    function fetchWinner(uint _poolId) private onlyOwner {
        uint[] memory alltickets = poolDetails[_poolId].allTickets;
        uint[] memory prizeTickets = new uint[](5);
        uint answer;

        for(uint i=0; i<5; i++){
            answer = generateRandomNumber(i);
            if(answer > alltickets.length){
                for(uint j=0; answer > alltickets.length; j++){
                    answer = answer / 2;
                    for(uint k=0; k < prizeTickets.length; k++){
                        if(prizeTickets[k] == answer){
                            answer = answer * 100;
                            answer = answer / 3;
                        }
                    }
                }
            }
            prizeTickets[i] = answer;
        }

        poolDetail storage PoolDetails = poolDetails[_poolId];
        for(uint i=0; i<5; i++){
            PoolDetails.prizeTickets.push(alltickets[prizeTickets[i]]);
        }

    }

    function generateRandomNumber(uint _nonce) internal view returns(uint16){
        return uint16(bytes2(keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            block.difficulty,
            msg.sender,
            _nonce
        ))));
    }

    function prizeTicket(uint _poolId) public view returns(uint[] memory){
        require(poolDetails[_poolId].status,"LOTTERY IS NOT ENDED");
        require(_poolId > 0 && _poolId <= numPoolId, "INVALID POOL ID");
        return poolDetails[_poolId].prizeTickets;
    }

    function claimPrice(uint _poolId) public {
        require(userTicketInfo[_msgSender()][_poolId].length > 0,"NOT AN PARTICIPANT");
        require(_poolId > 0 && _poolId <= numPoolId, "INVALID POOL ID");
        require(poolDetails[_poolId].status,"LOTTERY IS NOT ENDED");

        uint[] memory prizeTickets = poolDetails[_poolId].prizeTickets;
        uint[] memory userTickets = userTicketInfo[msg.sender][_poolId];

        for(uint i=0; i<userTickets.length; i++){
            for(uint j=0; j<prizeTickets.length; j++){
                if(userTickets[i] == prizeTickets[j]){
                    getPrizeAndRemove(_poolId,i,j);
                }
            }
        }
    }

    function getPrizeAndRemove(uint _poolId, uint _index, uint _userIndex) internal {
        
        uint divisor = poolDetails[_poolId].prizeTickets.length;

        poolDetail storage PoolDetails = poolDetails[_poolId];
        PoolDetails.prizeTickets[_index] = PoolDetails.prizeTickets[PoolDetails.prizeTickets[_index] - 1];
        PoolDetails.prizeTickets.pop();

        userTicketInfo[_msgSender()][_poolId][_userIndex] = 0;

        uint totalAmount = PoolDetails.totalAmountReceived;
        uint amountWithOutFees = (totalAmount / divisor);
        uint fees = (3 * amountWithOutFees) / 100;
        uint amountWithFee = amountWithOutFees - fees;

        PoolDetails.totalAmountReceived = PoolDetails.totalAmountReceived.sub(amountWithFee);

        IERC20(GRATToken).transfer(_msgSender(),amountWithFee);
        IERC20(GRATToken).transfer(owner(),fees);
    }
}