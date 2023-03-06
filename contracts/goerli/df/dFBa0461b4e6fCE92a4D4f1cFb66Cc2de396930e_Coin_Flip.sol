/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: UNLICENSED

// Tanay Patel

pragma solidity >=0.4.22 <0.9.0;

contract Coin_Flip{

    address[] internal userBetadress;

    struct User{
        uint Balance;       //User's Balance
        bool Status;        //Is user available for bet
        uint BetQuote;      // User Bet input
        uint Amount;        // Betting Amount
        bool intializer;    // User engaged or free
    }
    mapping(address => User) public Data; // Mapping address with users

    // Event 
    event Winners(
        address winnerAddress, 
        uint betAmount
    );
    
    function _placeBet(uint _amountToBet, uint _betOn) public{
        
        if(Data[msg.sender].intializer== false){
            Data[msg.sender].Balance = 100; // User balance set to 100 for all initially
            Data[msg.sender].intializer= true;  // User Engaged for bet
        }
        
        require(_amountToBet <= Data[msg.sender].Balance, "You are short on Money");
        require(Data[msg.sender].Status== false , "Bet Already Placed!");
        Data[msg.sender].Amount = _amountToBet;
        Data[msg.sender].Balance -= _amountToBet;
        Data[msg.sender].BetQuote = _betOn;
        Data[msg.sender].Status = true;
        userBetadress.push(msg.sender);
    }
    function _checkBets(address _add, uint rand) internal {
            require(Data[_add].Status== true , "you have not placed bet");

            // If user wins
            if(Data[_add].BetQuote == rand){
                Data[_add].Balance += (Data[_add].Amount*2);
                emit Winners(_add,Data[_add].Amount);
            } 

            // User again available for a bet
            Data[_add].Status = false;
        }

    // Passing bets placed
    function _rewardBet() public{
        uint length = userBetadress.length;

        //Implement Random Function Generator
        uint rand = uint(generateRand());
        rand = rand%2;  // To get values 0 or 1

        for(uint i=0;i<length; i++){
            _checkBets(userBetadress[i], rand);
        }
        delete userBetadress;
    }
    

// Issues with Harmony

    // function generateRand() private view returns (bytes32 result) {
	// 	bytes32 input;
	// 	assembly {
	// 		let Pointer := mload(0x40)
	// 				if iszero(staticcall(not(0), 0xff, input, 32, Pointer, 32)) {
	// 					invalid()
	// 				}
	// 				result := mload(Pointer)
	// 		}
  	// }



// Random Number Generator Function for betting outcome
    uint randNonce=0;
    function generateRand() internal returns (uint256) {
        randNonce++;
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randNonce)
                )
            );
    }

}