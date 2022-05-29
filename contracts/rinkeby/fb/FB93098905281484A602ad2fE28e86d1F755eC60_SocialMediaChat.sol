/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

// SPDX-License-Identifier: CC-BY-SA 4.0
//https://creativecommons.org/licenses/by-sa/4.0/

// TL;DR: The creator of this contract (@LogETH) is not liable for any damages associated with using the following code
// This contract must be deployed with credits toward the original creator, @LogETH.
// You must indicate if changes were made in a reasonable manner, but not in any way that suggests I endorse you or your use.
// If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
// You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.
// This TL;DR is solely an explaination and is not a representation of the licence.

// By deploying this contract, you agree to the licence above and the terms and conditions that come with it.

pragma solidity >=0.7.0 <0.9.0;

//// What is this contract? 

//// This contract is a simple messaging app
//// people can open a conversation with each other and send messages

//// Commissioned by ClippTube.eth#9594 on 5/25/2022

contract SocialMediaChat{
    
    address admin;

//// Variables that store post data:

    mapping(uint => mapping(uint => string)) Message;
    mapping(uint => mapping(uint => address)) MessageWriter;
    mapping(uint => address) Person1;
    mapping(uint => address) Person2;
    mapping(uint => ERC721) PostImage;
    mapping(uint => string) IPFS;
    mapping(uint => string) ChatTitle;
    mapping(uint => uint) PostImageTokenID;
    mapping(address => bool) public perms;
    mapping(uint => uint) public MessageNonce;
    mapping(uint => bool) public DoesChatExist;
    uint public ChatNonce;
    ERC20 ChatToken;
    ERC721 NFT;

    function EditChatToken(ERC20 TokenAddress) public {

        ChatToken = TokenAddress;
    }



    function CreateChat(string memory Title, address Who, string memory Image) public {

        ChatNonce += 1;
        DoesChatExist[ChatNonce] = true;

        IPFS[ChatNonce] = Image;
        ChatTitle[ChatNonce] = Title;

        Person1[ChatNonce] = msg.sender;
        Person2[ChatNonce] = Who;
    }

    function PostMessage(uint ChatID, string memory Text) public {

        require(DoesChatExist[ChatID] == true, "The Chat you're posting in does not exist!");
        require(msg.sender == Person1[ChatID] || msg.sender == Person2[ChatID], "You do not have permission to post a Message in this chat.");
        require(ChatToken.balanceOf(msg.sender) > 0 ,"You don't have enough tokens to send a message");

        ChatToken.transferFrom(msg.sender, address(this), 1);

        Message[ChatID][(MessageNonce[ChatID]+1)] = Text;
        MessageWriter[ChatID][MessageNonce[ChatID]+1] = msg.sender;
        MessageNonce[ChatID] += 1;
    }

    function ViewChat(uint ChatID) public view returns(string memory Title, string memory Description, string memory Image){

        require(ChatID != 0, "Chats start at 1, not zero");

        return(ChatTitle[ChatID], Message[ChatID][0], IPFS[ChatID]);
    }

    function ViewMessage(uint ChatID, uint MessageNumber) public view returns (string memory Text, address Writer){

        return (
            
            Message[ChatID][MessageNumber],
            MessageWriter[ChatID][MessageNumber]
            
        );
    }

    function EditPerms(address Who, bool TrueOrFalse) public {

        require(admin == msg.sender, "You aren't the admin so you can't press this button");
        perms[Who] = TrueOrFalse;
    }

    function isContract(address addr) internal view returns (bool) {

        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }       
}

interface ERC721{

    function balanceOf(address) external returns (uint);

}

interface ERC20{

    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function balanceOf(address) external returns (uint);
}