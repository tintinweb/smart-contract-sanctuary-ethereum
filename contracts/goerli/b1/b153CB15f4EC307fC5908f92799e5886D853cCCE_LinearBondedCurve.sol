// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract LinearBondedCurve {
    mapping(address => uint) public balances;
    uint public totalSupply;
    
    /// @dev Buy token. The price is linear to the total supply.
    function buy() public payable {
        uint tokenToReceive =  (1e18 * msg.value) / (1e18 + totalSupply);
        balances[msg.sender] += tokenToReceive;
        totalSupply += tokenToReceive;
    }
    
    /// @dev Sell token. The price of it is linear to the supply.
    /// @param _amount The amount of tokens to sell.
    function sell(uint _amount) public {
        uint ethToReceive = ((1e18 + totalSupply) * _amount) / 1e18;
        balances[msg.sender] -= _amount;
        totalSupply -= _amount;
        payable(msg.sender).transfer(ethToReceive);
    }
    
    /** @dev Send token.
     *  @param _recipient The recipient.
     *  @param _amount The amount to send.
     */
    function sendToken(address _recipient, uint _amount) public {
        balances[msg.sender]-=_amount;
        balances[_recipient]+=_amount;
    }
    
}

// encore une fois possible de transferer alors qu'on n'a pas les tokens ?

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