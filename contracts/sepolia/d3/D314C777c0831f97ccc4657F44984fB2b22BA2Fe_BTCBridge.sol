//                                                                          .                         
//                                                                       .JB#BPJ~.                    
//                                                                       ^[email protected]@@@@@&GY!:                
//                           .:~!?JJ?:                                     ~?5B&@@@@@&BY!:            
//                     .~7YPB#&@@@@@@#.                                        :~JP#@@@@@&GJ^         
//                  ^?P&@@@@@@@@@&#B5!                                             .^?5B&@@@@5:       
//               :[email protected]@@@@&#BPJ7~^:.                                                     :!5#@@&?      
//             ^Y&@@@#57~:.                                                                .?#@@P.    
//           ^5&@@#Y~.                                                                       [email protected]@5    
//         ^[email protected]@@#J.                                                            :75GB##BBGG5J!. ~PG.   
//       ^[email protected]@@#J.                                                           :?G#BP5JJYYYYY5PGG~       
//     [email protected]@@G7.                                                            !#P7?PB&[email protected]&&&&#GPJ:       
//    ^[email protected]@G~                ..:^^^^^:.                                     ..^[email protected]@#P:[email protected]@@@@@@@@B~      
//   ^&@G!           :~?YPGBB####&&&&&P                                    [email protected]@@#.  [email protected]@@@@@&[email protected]@~     
//   ^5?         :?PB#BGP5JJ7!~^:..:^~^                                   :[email protected]@@@B    [email protected]@@@@@&:#@&~    
//             7G&B55PGB#&&&@@&#BPJ~                                      [email protected]@@@@@7. :[email protected]@@@@@#:&@@&:   
//             ?Y7 [email protected]@@@@@@@@@@#J:                                  :@@&@@@@@#B&@@@@@@@[email protected]~&Y   
//           [email protected] [email protected]@@@@@@@@@@@&?                                 [email protected]@[email protected]@@@@@@@@@@@@@7.B7 ..   
//         :J#@@@@@G?:.  [email protected]@@@@@@@@@@@@@P.                               ~!! [email protected]@@@@@@@@@@@@&:^!.      
//        J&@@@[email protected]@@@&#B#@@@@@@@@@@@@@@@@5                               [email protected]#. [email protected]@@@@@@@@@@@J B#       
//       [email protected]@@P!..#@@@@@@@@@@@@@@@@@@@@@@@&:                              [email protected]#. [email protected]@@@@@@@@@@B [email protected]       
//      [email protected]@P^^57 ^&@@@@@@@@@@@@@@@@@@@[email protected]@J                              [email protected]&:  !&@@@@@@@@&~ [email protected]:       
//      [email protected] [email protected]  ~&@@@@@@@@@@@@@@@@@@:^@@B                               [email protected]?   ^[email protected]@@@@#Y: [email protected]?        
//     ^@B   [email protected]@~  ^#@@@@@@@@@@@@@@@@?  7??.                              ^#@7    ~JYJ~.  [email protected]         
//     !#~    [email protected]  :[email protected]@@@@@@@@@@@@&7  .PGY                                .Y&G?^.       J&?          
//            :#@P.   [email protected]@@@@@@@@@G^   [email protected]@5                                  :?G&&BY7~:7J:.           
//             :[email protected]#!    ^?5GBBGY7^    !&@B.                                     .!5B&@@@@PG#~         
//               ?#@G~             [email protected]@B:                                          .^~!!??7:         
//                [email protected]~.        [email protected]@@5.                                                             
//                   :?PB#PJ!^:~JP?^7J^                                                               
//                   [email protected]@@@@@&#GY^                                                                  
//                   .JBBGP5?7~:.                                                                     
//                                                                                                    
//                                                                                                    
//                                                                 .!.                                
//                                                       ^J7~^^:^!?J!                                 
//                                                        .^~!!!!~:                                   
//                                                                                                    
//                                                                                                    
//                                   ~ AAAAAAAAA IM BRIDGINGGGGG ~                                     
//                              Bitcoin Miladys ERC-20 => BRC-20E Bridge
//                                https://bitcoinmiladys.com/linkhere
//                                  Smart Contract by @shrimpyuk :^)
//

pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 
contract BTCBridge {
    /// @notice Burn ERC-20 Tokens to bridge them to BRC-20E
    /// @param _tokenAddress The Address of the Token's Contract to burn
    /// @param _amount Amount of tokens to Burn
    /// @param _btcAddress the Bitcoin Address to receive the tokens to. Ensure 
    function burnForBridge(address _tokenAddress, uint256 _amount, bytes32 _btcAddress) external {
        //todo: Validate _btcAddress

        //Create ERC-20 Instance of Token
        IERC20 token = IERC20(_tokenAddress);
        //Validate wallet holds enough tokens and the token allowance is high enough
        require(token.balanceOf(msg.sender) >= _amount && token.allowance(msg.sender, address(this)) >= _amount, "Not enough tokens to burn or allowance too low");

        //Send tokens to 0x000000000000000000000000000000000000dEaD (Recognised Burn Wallet)
        bool success = token.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, _amount);
        require(success, "Token Burn Failed");

        //Emit Event for Bridge to process TX
        emit BurnForBridge(msg.sender, _tokenAddress, _amount, _btcAddress);
    }

    //Burn Event
    event BurnForBridge(address indexed user, address indexed token, uint256 amount, bytes32 btcAddress);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}