pragma solidity ^0.8.0;
/// @title Jaypigs
/// @author Youssefea - [email protected]
/// @notice You can use this contract for only the most basic simulation
/// @dev All function calls are currently implemented without side effects
/// @custom:experimental This is an experimental contract.

import "./jaypigsTools.sol";
import "./jaypigsStorage.sol";

contract jaypigsRewards is Ownable {

    
    address storageAddress;
    address tokenAddress;

    event Claimed(address claimer, uint amount);
    event Wrapped(bool result, bytes data);

    jaypigsStorage storageContract;

    constructor(){
        storageAddress=address(0);
    }

    /**
     * @notice set the rewards contract address
     */
    function setStorage(address _storageAddress) external onlyOwner{
        storageAddress=_storageAddress;
        storageContract=jaypigsStorage(storageAddress);
        tokenAddress=storageContract.getTokenForOffer();
    }



    function wrapEth() external {

        
        (bool success, bytes memory data) = tokenAddress.call{value: address(this).balance}(
            abi.encodeWithSignature("deposit()")
        );

        emit Wrapped(success, data);

        
    }



    function claimWETH() external returns (bool){

        uint256 userBalance=storageContract.getBalance(msg.sender);

        //require that he has enough balance
        require(userBalance>0, "You have no balance");

        //updating the amount of his claims
        storageContract.setClaims(msg.sender,storageContract.getClaims(msg.sender)+userBalance);

        //sending ether
        if (IERC20(tokenAddress).balanceOf(address(this))<userBalance){
            (bool success, bytes memory data) = tokenAddress.call{value: address(this).balance}(
            abi.encodeWithSignature("deposit()") );
        }

        IERC20(tokenAddress).transferFrom(address(this),msg.sender,userBalance);

        //returns true if success
        return(true);

        emit Claimed(msg.sender, userBalance);


    }





}