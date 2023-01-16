// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

contract Store {
    bool public chosen; // True if head/tail has been chosen.
    bool lastChoiceHead; // True if the choice is head.
    address payable public lastParty; // The last party who chose.
    
    /** @dev Must be sent 1 ETH.
     *  Choose head or tail to be guessed by the other player.
     *  @param _chooseHead True if head was chosen, false if tail was chosen.
     */
    function choose(bool _chooseHead) public payable {
        require(!chosen);
        require(msg.value == 1 gwei);
        
        chosen=true;
        lastChoiceHead=_chooseHead;
        lastParty=payable(msg.sender);
    }
    
    
    function guess(bool _guessHead) public payable {
        require(chosen);
        require(msg.value == 1 gwei);
        
        if (_guessHead == lastChoiceHead)
            payable(msg.sender).transfer(2 gwei);
        else
            lastParty.transfer(2 gwei);
            
        chosen=false;
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