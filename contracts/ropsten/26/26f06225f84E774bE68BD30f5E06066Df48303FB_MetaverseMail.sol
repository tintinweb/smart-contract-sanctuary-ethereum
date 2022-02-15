// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

contract MetaverseMail {

    address public admin;
    uint256 public messageCost = 100000000000000; //0.0001 ETH

    struct MailAccount {
        address addres;
        uint256 numMail;
        string[] mailIds;
    }

    // mapping of addresses that have SENT mail
    mapping (address => MailAccount) public sentAccounts;

    // mapping of addresses that have RECEIVED mail
    mapping (address => MailAccount) public receiveAccounts;
    
    event MailRegister (
        address _senderAddress,
        address _recipientAddress,
        uint256 indexed sendFee
    );

    constructor(){
        admin = msg.sender;
    }


    /*
    * <mail_id> is generated at the client end
    */
    function sendMail (address _sender, address _receiver, string memory mail_id) payable public {

        require ( msg.value >= messageCost, "You do not have enough funds to send mail" );
        registerSentMail(_sender, mail_id);
        registerReceivedMail(_receiver, mail_id);   
    }

    // Register mail that has sent mail
    function registerSentMail (address _sender, string memory mail_id) internal {

        if ( accountExists(_sender, sentAccounts) ) {
            // Update sent mail account with new mail id
            MailAccount storage sentAccount = sentAccounts[_sender];
            sentAccount.numMail = sentAccount.numMail + 1;
            sentAccount.mailIds.push(mail_id); 
        } else {
            // Create new sent mail account AND add new mail id
            MailAccount storage newSentAccount = sentAccounts[_sender];
            newSentAccount.addres = _sender;
            newSentAccount.numMail = 1;
            newSentAccount.mailIds.push(mail_id); 
        }
    }

    // Register address that has received mail
    function registerReceivedMail (address _receiver, string memory mail_id) internal {

        if ( accountExists(_receiver, receiveAccounts) ) {
            // Update received mail account with new mail id
            MailAccount storage receiveAccount = receiveAccounts[_receiver];
            receiveAccount.numMail = receiveAccount.numMail + 1;
            receiveAccount.mailIds.push(mail_id);
        } else {
            // Create new received mail account AND add new mail id
            MailAccount storage newReceiveAccount = receiveAccounts[_receiver];
            newReceiveAccount.addres = _receiver;
            newReceiveAccount.numMail = 1;
            newReceiveAccount.mailIds.push(mail_id);   
        }
    }


    function accountExists (address _addr, mapping(address => MailAccount) storage accounts ) internal view returns (bool) {

        if ( accounts[_addr].numMail != 0 ) {
            return true;
        } else {
            return false;
        }
    }

    // UPDATE THE COST EACH MESSAGE
    function updateMessageCost (uint256 newCost) public {
        require(msg.sender == admin);
        messageCost = newCost;
    }


}