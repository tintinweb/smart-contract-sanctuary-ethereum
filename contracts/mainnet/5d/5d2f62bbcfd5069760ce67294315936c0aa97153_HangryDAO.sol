/**
 *Submitted for verification at Etherscan.io on 2022-12-28
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.17;


interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


interface IERC721 is IERC165 {
   
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


    interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


    contract HangryDAO{

        // variables
        uint256 public counters;
                    // mapping
        mapping(address=>bool) public admins;    
        mapping(address=>bool) public moderators;
        mapping(uint256=>proposal) public submittedProposal;   

    constructor() {
        admins[msg.sender] =true;
    }

     
    //////////////////////////////////////////////
                    // structure
    struct proposal{
        uint256 proposalID;
        string title;
        string description;
        uint256 startingDate;
        uint256 endingDate;
        bool poll;
        string result;
        bool approved;
                     }

                    // modifiers

    modifier OnlyAdmin(){
        require(admins[msg.sender] ==true , "Ownable: caller is not the admin");
        _;
    } 

    modifier Onlymoderators(){
        require(moderators[msg.sender] ==true , "Ownable: caller is not the moderator");
        _;
    }


        
    //////////////////////////////////////////////
                    //admin functionality

//  ADMIN of the contract make new admins
    // param _Addr : new admin address
    // only callable by any of the existing admins
    function addAdmins(address _Addr) public OnlyAdmin {
        admins[_Addr] =true;
    }

//  ADMIN of the contract  remove admins
    // param _Addr : existing admin address
    // only callable by any of the existing admins

    function removeAdmins(address _Addr) public OnlyAdmin {
        admins[_Addr] =false;
    }

//  ADMIN of the contract  add moderators
    // param _Addr : new moderator address
    // only callable by any of the existing admins

    function addModerator(address _Addr) public OnlyAdmin {
        moderators[_Addr] =true;
    }

//  ADMIN of the contract  remove moderators
    // param _Addr : existing moderator address
    // only callable by any of the existing admins

    function removeModerator(address _Addr) public OnlyAdmin {
        moderators[_Addr] =false;
    }

            //////////////////////////////////////////////
                        //modifiers functionality

    // moderator of this contract can add the proposal
    // params _title: is the title of proposal (a string)
    // _description: description of the proposal (a string)
    // _ending time: end time of proposal (integer)
    // _poll: must be in true/false (boolean)
    //  _result: result of the proposal (a string)


    function createProposal( string memory _title, string memory _description,/* uint256 _startingDate,*/
     uint256 _endingDate, bool _poll, string memory _result) public Onlymoderators {
         submittedProposal[counters].proposalID=counters;
         submittedProposal[counters].title=_title;
         submittedProposal[counters].description=_description;
         submittedProposal[counters].startingDate=block.timestamp;
         submittedProposal[counters].endingDate=_endingDate;
         submittedProposal[counters].poll=_poll;
         submittedProposal[counters].result=_result;
         counters++;
    }


// only moderator address can delete the some specific proposal 
// param _countNumber : proposal number

    function deleteProposal(uint256 _countNumber) public Onlymoderators {
         submittedProposal[_countNumber].proposalID=0;
         submittedProposal[_countNumber].title="";
         submittedProposal[_countNumber].description="";
         submittedProposal[_countNumber].startingDate=0;
         submittedProposal[_countNumber].endingDate=0;
         submittedProposal[_countNumber].poll=false;
         submittedProposal[_countNumber].result="";
         counters--;
    }
    
    // only moderator address can approved the some specific proposal 
// param _countNumber : proposal number
// _status : is the status of proposal must be in true/false (boolean)


    function approvedProposal(uint256 _countNumber,bool _status) public Onlymoderators{
        submittedProposal[_countNumber].approved=_status;
    }

        // only moderator address can edit the the some specific proposal 
// param _proposalID : is proposal number (integer)
 // params _title: is the title of proposal (a string)
    // _description: description of the proposal (a string)
    // _ending time: end time of proposal (integer)
    // _poll: must be in true/false (boolean)
    //  _result: result of the proposal (a string)

    function editProposal(uint256 _proposalID, string memory _title, string memory _description,/* uint256 _startingDate,*/
     uint256 _endingDate, bool _poll, string memory _result) public Onlymoderators {
         submittedProposal[_proposalID].proposalID=_proposalID;
         submittedProposal[_proposalID].title=_title;
         submittedProposal[_proposalID].description=_description;
         submittedProposal[_proposalID].startingDate=block.timestamp;
         submittedProposal[_proposalID].endingDate=_endingDate;
         submittedProposal[_proposalID].poll=_poll;
         submittedProposal[_proposalID].result=_result;
        
    }

    // recieves the eth
      receive() external payable {
      
    }

    //owner withdrawal
    // param _addr : erc20 token address
    // _amount : number of tokens

    function withdrawERC(IERC20 _addr,uint256 _amount) public OnlyAdmin{
        IERC20(_addr).transfer(msg.sender,_amount);
    }


    
    //owner withdrawal
    // param _addr : erc721 token address
    // _amount : tokenID
    
    function withdrawERC721(IERC721 _addr,uint256 _amount) public OnlyAdmin{
        IERC721(_addr).transferFrom(address(this),msg.sender,_amount);
    }

    //owner withdrawal
    // _amount : number of eth to withdraw

    function rescueEther(uint256 _amount) public OnlyAdmin{
        payable(msg.sender).transfer(_amount);
    }

    function depositNFT(IERC721 _NFTaddr,uint256 _tokenID) public OnlyAdmin{
        _NFTaddr.transferFrom(msg.sender,address(this),_tokenID);
    }




}