/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

/**
 *Submitted for verification at FtmScan.com on 2022-05-23
*/

// SPDX-License-Identifier: CC-BY-SA 4.0
//https://creativecommons.org/licenses/by-sa/4.0/

// TL;DR: The creators of this contract (@LogETH) (@jellyfantom) are not liable for any damages associated with using the following code
// This contract must be deployed with credits toward the original creators, @LogETH @jellyfantom.
// You must indicate if changes were made in a reasonable manner, but not in any way that suggests we endorse you or your use.
// If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
// You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.
// This TL;DR is solely an explaination and is not a representation of the licence.

// By deploying this contract, you agree to the licence above and the terms and conditions that come with it.

pragma solidity >=0.7.0 <0.9.0;

//// What is this contract? 

//// This contract is a backend for a decentralized social media with threads and stuff


contract SocialMediaThread{
    
    address admin;

//// Variables that store post data:

    mapping(uint => mapping(uint => string)) Comment;
    mapping(uint => mapping(uint => address)) CommentWriter;
    mapping(uint => ERC721) PostImage;
    mapping(uint => string) IPFS;
    mapping(uint => string) ThreadTitle;
    mapping(uint => uint) PostImageTokenID;
    mapping(address => bool) public perms;
    mapping(uint => uint) public CommentNonce;
    mapping(uint => bool) public DoesThreadExist;
    mapping(uint => mapping(uint => uint)) Likes;
    mapping(address => mapping(uint => mapping(uint => bool))) AlreadyLiked;
    uint public ThreadNonce;
    ERC721 NFT;

    constructor(){

        admin = msg.sender; 
        NFT = ERC721(0x0000000000000000000000000000000000000000); // Change this to the NFT collection you would like to use

    }

    function Like(uint ThreadID, uint CommentNumber) public {

        require(AlreadyLiked[msg.sender][ThreadID][CommentNumber] != true, "You can't like the same comment twice");
        Likes[ThreadID][CommentNumber] += 1;
    }

    function ViewLikes(uint ThreadID, uint CommentNumber) public view returns(uint){

        return Likes[ThreadID][CommentNumber];
    }


    function CreateThread(string memory Title, string memory Description, string memory Image) public {

        require(admin == msg.sender || perms[msg.sender] == true, "You do not have permission to create a thread.");

        ThreadNonce += 1;
        DoesThreadExist[ThreadNonce] = true;

        Comment[ThreadNonce][0] = Description;

        IPFS[ThreadNonce] = Image;
        ThreadTitle[ThreadNonce] = Title;
    }

    function PostComment(uint ThreadID, string memory Text) public {

        require(DoesThreadExist[ThreadID] == true, "The thread you're posting in does not exist!");
        require(NFT.balanceOf(msg.sender) >= 1, "You do not have permission to post a comment.");

        Comment[ThreadID][(CommentNonce[ThreadID]+1)] = Text;
        CommentWriter[ThreadID][CommentNonce[ThreadID]+1] = msg.sender;
        CommentNonce[ThreadID] += 1;
    }

    function ViewThread(uint ThreadID) public view returns(string memory Title, string memory Description, string memory Image){

        require(ThreadID != 0, "Threads start at 1, not zero");

        return(ThreadTitle[ThreadID], Comment[ThreadID][0], IPFS[ThreadID]);
    }

    function ViewComment(uint ThreadID, uint CommentNumber) public view returns (string memory Text, address Poster){

        return (
            
            Comment[ThreadID][CommentNumber],
            CommentWriter[ThreadID][CommentNumber]
            
        );
    }

    function EditNFT(ERC721 WhichNFT) public {

        require(admin == msg.sender || perms[msg.sender] == true, "You aren't the admin so you can't press this button");
        require(isContract(address(WhichNFT)) == true, "The address you put in is not a contract.");

        NFT = WhichNFT;
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
    function balanceOf(address) external returns (uint);
}