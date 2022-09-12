/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

/**
 *Submitted for verification at BscScan.com on 2022-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IERC20 
{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

abstract contract ReentrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

contract CkioLottery is ReentrancyGuard {

    address private maincontract = 0x97477CEc3a72c55cD4Db0bB26f676295046eb253;
    uint256 private fee = 10;
    address private owner;
    uint256 private maxParticipantNumbers;
    uint256 private participantNumbers;
    uint256 private ticketPrice;
    address payable[] participants;
    bool public lotteryStarted = false;
    address[] public winnerLottery;
    address public tokenAddress;
    IERC20 public BusdInterface;

    constructor()  {  
        owner =  msg.sender;
        maxParticipantNumbers = 100;
        ticketPrice = 1 ether ;

        tokenAddress = 0x3425787725A8Fac88eA74a4f15745460A1706346;
        BusdInterface = IERC20(tokenAddress);
    }
    
    event logshh(uint256 _id, uint256 _value);

    function lotteryBalance() public view returns(uint256) {
        return BusdInterface.balanceOf(address(this));
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Access denied!");
        _;
    }
    modifier notOwner(){
        require(msg.sender != owner, "Access denied!");
        _;
    }
    
    function setTicketPrice(uint256 _valueInEther) public onlyOwner{
        ticketPrice = _valueInEther;
    }
    
    function setMaximmNumbers(uint256 _maxNumbers) public onlyOwner{
        maxParticipantNumbers = _maxNumbers;
    }

    function viewTicketPrice() external view returns(uint256){
        return ticketPrice;
    }
    function viewTicket() external view returns(uint256){
        return maxParticipantNumbers;
    }

    function startLottery() public onlyOwner(){
        lotteryStarted = true;
    }

    function announceLottery() public onlyOwner(){
        pickwinner();
    }
    
    function joinLottery(uint256 _amount) external notOwner() noReentrant{
        require(lotteryStarted , "Lottery is not started yet");
        require(_amount== ticketPrice,"Not same amount" );
        bool chk= BusdInterface.transferFrom(msg.sender,address(this),_amount);
        if(chk){
            if (participantNumbers < maxParticipantNumbers){
                participants.push(payable(msg.sender));
                participantNumbers++;
                if (participantNumbers == maxParticipantNumbers){
                    pickwinner();
                }
            }
            else if (participantNumbers == maxParticipantNumbers){
                pickwinner();
            }
        }
    }
    
    
    function random() private view returns(uint256){
        return uint256(keccak256(abi.encode(block.difficulty, block.timestamp, participants, block.number)));
    }

    function getLotteryLength() public view returns(uint256){
        return participants.length;
    }

    function howMany(address ad) public view returns(uint256){
        uint256 lHm=0;
        uint arrayLength = participants.length;
        if(arrayLength!=0){
            for (uint i=0; i<arrayLength; i++) {
                if (participants[i]==ad){
                    lHm++;
                }
            }
        }
        return (lHm);
    }

    
    function pickwinner() internal {
        uint win = random() % participants.length;
        uint256 totalUsers = participants.length ;
        uint256 contractBalance = ticketPrice * totalUsers;
        uint256 maincontractFee = SafeMath.div(SafeMath.mul(contractBalance,fee),100);
        BusdInterface.transfer(maincontract,maincontractFee);
        uint256 winnerAmount = SafeMath.sub(contractBalance,maincontractFee);
        BusdInterface.transfer(participants[win],winnerAmount);
        winnerLottery.push(participants[win]);
        delete participants;
        participantNumbers = 0;
    }


    function allWinner() public view returns(address[] memory){
        address[] memory result= new address[](17);
        uint256 arrayLength = winnerLottery.length;
        uint256 resultLength = result.length;
        uint256 index =0;
        if(arrayLength>10){
                for (uint256 i=arrayLength; i>(arrayLength-10); i--) {
                    resultLength++;
                    result[resultLength]=winnerLottery[i];
                }
        }
        else {
            for (uint256 i=arrayLength; i>0; i--) {
                resultLength++;
                address payable _address = payable(winnerLottery[i-1]);
                result[index]=_address;
                index++;
            }
        }
        return result;
    }
}