/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// File: IERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IERC20Metadata {
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 is IERC20Metadata {
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

// File: Pool.sol


pragma solidity ^0.8.0;


contract PoolBet{
    address immutable public admin;
    IERC20 immutable public token;
    

    constructor(){
        admin = payable(msg.sender);
        token = IERC20(0xe10DCe92fB554E057619142AbFBB41688A7e8D07);
    }


    mapping(address => mapping(uint=> string )) betIdtoChoice;
    mapping(address => mapping(uint => uint)) betidToStake;
    mapping(address => mapping(uint => bool)) CalledFinalise;
    mapping(uint => uint) public betIdtoTotal;
    mapping(uint => string) public betidToResult;
    mapping(uint => bool) public betEnded;
    mapping(uint => bool) public betStarted;
    mapping(uint => uint) public betCount;
    mapping(uint => mapping(uint => address)) public betidtoAddresses;
    mapping(uint => mapping(uint => address)) public winners;



    function Stake(uint betid, uint stakeAmount, string memory _choice) external{
        require(!betEnded[betid], "AE");//Already Ended
        require(!betStarted[betid], "AS");//Already Started
            
            betCount[betid] ++;

             token.approve(address(this), stakeAmount);
             token.transferFrom(msg.sender, address(this), stakeAmount);
             betIdtoChoice[msg.sender][betid] = _choice;
             betidToStake[msg.sender][betid] = stakeAmount;
             betIdtoTotal[betid] += stakeAmount;

             

             betidtoAddresses[betid][betCount[betid]] = msg.sender;
             

        
    }

    function checkmatchStarted(uint betid, bool status) public{
     require(!betEnded[betid], "AE");//Already Ended
        require(!betStarted[betid], "AS");//Already Started

        betStarted[betid] = status;
    }

    
    function checkMatchEnded(uint betid, bool status) public{
        require(!betEnded[betid], "AE");//Already Ended
        require(betStarted[betid], "NS");//Not Started

        betEnded[betid] = status;

    }

    function setBetResult(uint betid, string memory result) public{
        require(betEnded[betid], "AE");//Not Ended
        betidToResult[betid] = result;
    }


    function compareStrings(string memory a, string memory b) public pure returns (bool) { 
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)); 
    }


    function finalise(uint betid) external{

        require(betEnded[betid], "AE");//Not Ended
        require(betidToStake[msg.sender][betid]> 0, "DNS");//DId not stake

        uint winnercount;
        uint losercount;
        uint winnershare;
        uint winneramount;



        /*
        This for loop checks for each choice for each address involved in the bet, when the choice is equal to the result, 
        the number of winners increas(einner count) and it also stores the amount of tokens they staked originally (winneramount)
        which is later used to calculate the percentage of tokens they will receive from the winnershare

        WInnershare is the total number of token staked by the losers, the winners will be sharing it based on the percentage 
        of tokens they have in winneramount, if there is a loser, the loser count goes up
        */

        
        for(uint i = 1; i<= betCount[betid]; i++){
        address staker = betidtoAddresses[betid][i];
        bool correct = compareStrings(betIdtoChoice[staker][betid], betidToResult[betid]);

           if(correct == true){


               winnercount++;

               winners[betid][winnercount] = staker;
               winneramount += betidToStake[staker][betid];

           } else {
            
                if(correct == false){
                    losercount++;
                    winnershare += betidToStake[staker][betid];
                 }
           
           }

            
        
        }


        //
        //
        //

    /*
        first condition checks if there are no losers, which means either all stakers chose one option or the third option which was not chosen is the answer
        it will refund them 100%
    */
        //
        //
        //
        //
        if(losercount == 0){
            
            for(uint i = 1; i<= betCount[betid]; i++){
                address staker = betidtoAddresses[betid][i];
                uint amount = betidToStake[staker][betid];


                delete betidToStake[staker][betid];
                delete betIdtoChoice[staker][betid];


                token.transfer(staker, amount);


            }
        }else
        //
        //
        //
        //

    /*
        Sencond condition checks if all stakers lost, if that is true, it will refund 90% of each stake and the remaining 10% goes to admin
    */

        //
        //
        //
        //

         if(losercount == betCount[betid]){
             for(uint i = 1; i<= betCount[betid]; i++){
                address staker = betidtoAddresses[betid][i];

                uint lfee = betidToStake[staker][betid] * 1000/10000;

                uint amount = betidToStake[staker][betid] - lfee;

                delete betidToStake[staker][betid];
                delete betIdtoChoice[staker][betid];


                token.transfer(staker, amount);

                token.transfer(admin, lfee);


            }
        }   else 
         //
        //
        //
        //

    /*
        third condition checks if there are any losers
        in which case the winners will split the loser's stake according to their percentage 
    */

        //
        //
        //
        //
        if(losercount > 0){
            
            uint fee = winnershare * 1000/10000;

            uint newAmount = winnershare - fee;

            for(uint i = 1; i <= winnercount; i++){
                address staker = winners[betid][i];
                uint personalStake = betidToStake[staker][betid];

                uint percentage = personalStake * 10000/ winneramount;

                
                uint payout =personalStake + (newAmount * percentage/10000);

                delete betidToStake[staker][betid];
                delete betIdtoChoice[staker][betid];
                delete winners[betid][i];
                delete betidtoAddresses[betid][i];


                token.transfer(staker, payout);


            }

            
            token.transfer(admin, fee);

        }

        

        
    }
   
}