// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


// import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721A.sol";
import "./FxBaseRootTunnel.sol";

contract NFTStaker is FxBaseRootTunnel, Ownable{

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

    constructor(address _checkpointManager, address _fxRoot, address _contractAddress) FxBaseRootTunnel(_checkpointManager, _fxRoot){
         parentContract = ERC721A(_contractAddress);
    }

    function _processMessageFromChild(bytes memory data) internal override {
        //Nothing to process from child.
    }


    function stake(uint256 _tokenId) public { 
        require(contractState, "Staking is currently not available");
        //User can only stake once
        require(userInfo[msg.sender].timestamp == 0, "User has already staked");
        userInfo[msg.sender] = Stake(_tokenId, block.timestamp);

        // Send only the wallet address and action (true => staking)
        _sendMessageToChild(abi.encode(msg.sender, true));
        parentContract.transferFrom(msg.sender, address(this), _tokenId);
    }

    function unstake() public {
        require(userInfo[msg.sender].timestamp != 0, "User has not staked anything yet");

        // Send only the wallet address and action (false => unstake)
        _sendMessageToChild(abi.encode(msg.sender, false));
        parentContract.transferFrom(address(this), msg.sender, userInfo[msg.sender].tokenId); 
        delete userInfo[msg.sender];
    }

    
    function getTimeStaked(address _address) public view returns(uint256){
        //Show the time duration (seconds) of the user stake
        require(userInfo[_address].timestamp != 0, "User has not staked anything yet");
        return(block.timestamp - userInfo[_address].timestamp);
    }
    

    //Owner functions
    function toggleState() public onlyOwner{
        //Either enable or disable staking
        contractState = !contractState;
    }


}