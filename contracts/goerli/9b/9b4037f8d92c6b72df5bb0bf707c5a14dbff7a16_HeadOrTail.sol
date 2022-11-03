/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

//*** Exercice 3 ***//
// You choose Head or Tail and send 1 ETH.
// The next party send 1 ETH and try to guess what you chose.
// If it succeed it gets 2 ETH, else you get 2 ETH.
contract HeadOrTail {
    bool public chosen; // True if head/tail has been chosen.
    bool lastChoiceHead; // True if the choice is head.
    address payable public lastParty; // The last party who chose.
    
    /** @dev Must be sent 1 ETH.
     *  Choose head or tail to be guessed by the other player.
     *  @param _chooseHead True if head was chosen, false if tail was chosen.
     */
    function choose(bool _chooseHead) public payable {
        require(!chosen);
        require(msg.value == 0.01 ether);
        
        chosen=true;
        lastChoiceHead=_chooseHead;
        lastParty=payable(msg.sender);
    }
    
    
    function guess(bool _guessHead) public payable {
        require(chosen);
        require(msg.value == 1 ether);
        
        if (_guessHead == lastChoiceHead)
            payable(msg.sender).transfer(2 ether);
        else
            lastParty.transfer(2 ether);
            
        chosen=false;
    }
}