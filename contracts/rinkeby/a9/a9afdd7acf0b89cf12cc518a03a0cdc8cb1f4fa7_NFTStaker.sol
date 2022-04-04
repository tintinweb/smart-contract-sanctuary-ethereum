// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


// import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

contract NFTStaker is Ownable{

    struct Stake {
        uint256 tokenId;
        uint256 timestamp;
    }

    //Map staker address to stake details
    mapping(address => Stake) public userInfo;

    //map staker to total staking time (in seconds)
    mapping(address => uint256) public stakingTime;

    //Staking control
    bool public contractState = false;

  ERC721A public parentContract;

    constructor(){
         parentContract = ERC721A(0x536EB48c9bA852D87b7865bcE846DD2F8F97fA1e);
    }


    function stake(uint256 _tokenId) public {
        require(contractState, "Staking is currently not available");
        userInfo[msg.sender] = Stake(_tokenId, block.timestamp);
        parentContract.transferFrom(msg.sender, address(this), _tokenId);
    }

    function unstake() public {
        require(userInfo[msg.sender].timestamp != 0, "User has not staked anything yet");
        parentContract.transferFrom(address(this), msg.sender, userInfo[msg.sender].tokenId); 
        delete userInfo[msg.sender];
    }


    
    function getTimeStaked() public view returns(uint256){
        //Show the time duration (seconds) of the user stake
        require(userInfo[msg.sender].timestamp != 0, "User has not staked anything yet");
        return(block.timestamp - userInfo[msg.sender].timestamp);
    }
    

    //Owner functions
    function toggleState() public onlyOwner{
        //Either enable or disable the contract
        contractState = !contractState;
    }


}