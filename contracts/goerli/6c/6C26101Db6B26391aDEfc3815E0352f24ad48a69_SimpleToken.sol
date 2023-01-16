// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleToken {
    mapping(address => int) public balances;
    
    /// @dev Creator starts with all the tokens.
    constructor()  {
        balances[msg.sender]+= 1000e18;
    }
    
    /** @dev Send token.
     *  @param _recipient The recipient.
     *  @param _amount The amount to send.
     */
    function sendToken(address _recipient, int _amount) public {
        balances[msg.sender]-=_amount;
        balances[_recipient]+=_amount;
    }
    
}

// contract Store {
//     struct Safe {
//         address owner;
//         uint amount;
//     }
    
//     Safe[] public safes;
    
//     /// @dev Store some ETH.
//     function store() public payable {
//         safes.push(Safe({owner: msg.sender, amount: msg.value}));
//     }
    
//     /// @dev Take back all the amount stored.
//     function take() public {
//         for (uint i; i<safes.length; ++i) {
//             Safe storage safe = safes[i];
//             if (safe.owner==msg.sender && safe.amount!=0) {
//                 payable(msg.sender).transfer(safe.amount);
//                 safe.amount=0;
//             }
//         }
        
//     }
// }