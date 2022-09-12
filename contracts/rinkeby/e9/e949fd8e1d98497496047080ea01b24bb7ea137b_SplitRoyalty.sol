/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier: MIT

//This contract address should be given to royalty receiver address on the marketplaces where your NFT collection will be listed
pragma solidity ^0.8.0;

contract SplitRoyalty {
   
    struct userShare{
        address walletAddress;
        uint256 percentageShare;
    }

    userShare[] public userShares;

    event Received(address, uint256);
    event RoyaltyTransferred(address, uint256);

    constructor(){
        //Treasury Wallet
        userShares.push(userShare(0x891cadfef0bfb52D7deE59157bE3d121C7C0f47d,4000));

        //Dev Wallets
        userShares.push(userShare(0x891cadfef0bfb52D7deE59157bE3d121C7C0f47d,1000)); //Alpha
        userShares.push(userShare(0x891cadfef0bfb52D7deE59157bE3d121C7C0f47d,1000)); //Jon
        userShares.push(userShare(0x891cadfef0bfb52D7deE59157bE3d121C7C0f47d,1000)); //Amir
        
        //Early Holder wallets
        userShares.push(userShare(0x891cadfef0bfb52D7deE59157bE3d121C7C0f47d,200));
        userShares.push(userShare(0x891cadfef0bfb52D7deE59157bE3d121C7C0f47d,200));
        userShares.push(userShare(0x891cadfef0bfb52D7deE59157bE3d121C7C0f47d,200));
        userShares.push(userShare(0x891cadfef0bfb52D7deE59157bE3d121C7C0f47d,200));
        userShares.push(userShare(0x891cadfef0bfb52D7deE59157bE3d121C7C0f47d,200));
        userShares.push(userShare(0x891cadfef0bfb52D7deE59157bE3d121C7C0f47d,200));
        userShares.push(userShare(0x891cadfef0bfb52D7deE59157bE3d121C7C0f47d,200));
        userShares.push(userShare(0x891cadfef0bfb52D7deE59157bE3d121C7C0f47d,200));
        userShares.push(userShare(0x891cadfef0bfb52D7deE59157bE3d121C7C0f47d,200));
        userShares.push(userShare(0x891cadfef0bfb52D7deE59157bE3d121C7C0f47d,200));
        userShares.push(userShare(0x891cadfef0bfb52D7deE59157bE3d121C7C0f47d,200));
        userShares.push(userShare(0x891cadfef0bfb52D7deE59157bE3d121C7C0f47d,200));
        userShares.push(userShare(0x891cadfef0bfb52D7deE59157bE3d121C7C0f47d,200));
        userShares.push(userShare(0x891cadfef0bfb52D7deE59157bE3d121C7C0f47d,200));
        userShares.push(userShare(0x891cadfef0bfb52D7deE59157bE3d121C7C0f47d,200));
    }

    function getPercentageShare(uint256 totalBalance, uint256 _percentage) public pure returns(uint256){
        return (totalBalance*_percentage)/10000;
    }
    
    function transferRoyalty() public  {
        bool transfer_success;
        uint256 totalBalance = address(this).balance;
        for(uint256 i=0; i < userShares.length; i++){
            (transfer_success, ) = userShares[i].walletAddress.call{value: getPercentageShare(totalBalance, userShares[i].percentageShare)}("");
            require(transfer_success, "Transfer 1 failed.");
            emit RoyaltyTransferred(userShares[i].walletAddress, userShares[i].percentageShare);
            transfer_success = false;
        }
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
        transferRoyalty();
    }
}