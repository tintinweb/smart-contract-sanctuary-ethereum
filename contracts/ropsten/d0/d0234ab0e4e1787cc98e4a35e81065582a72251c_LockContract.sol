//SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";

contract LockContract is Ownable {
    using SafeMath for uint256;
    using Address for address;

    enum EAmountType{
        None,
        Coin,
        ERC20
    }

    enum EAmountStatus{
        None,
        Locked,
        Unlocked
    }

    struct Investment{
        address userAddress;
        address tokenAddress;
        uint256 lockAmount;
        uint256 lockDate;
        uint256 unlockDate;
        EAmountType amountType;
        EAmountStatus amountStatus;
    }
    
    mapping (bytes32 => Investment) public investments;

    constructor(){}

    function getInvestment(bytes32 uniqueKey) private view returns (Investment memory){
        return investments[uniqueKey];
    }    

    function updateInvestment(Investment memory investment, bytes32 uniqueKey ) private returns (Investment memory){
        investments[uniqueKey] = investment;

        return investment;
    }

    //Contract unique key
    function getPrivateUniqueKey(address contractAddress, address userAddress) private pure returns (bytes32){
        return keccak256(abi.encodePacked(contractAddress, userAddress));
    }

    function tokenInvestment(address tokenContractAddress, uint256 tokenAmount, uint256 lockTimeInSeconds) external returns (Investment memory){
         bytes32 uniqueKey = getPrivateUniqueKey(tokenContractAddress, msg.sender);

        Investment memory investment = getInvestment(uniqueKey);

        if(tokenAmount <= 0){
            revert("amount should be greater than 0.");
        }

        uint256 unlocktimeInSeconds = getDateTimeNowInSeconds().add(lockTimeInSeconds);

        if (investment.amountStatus == EAmountStatus.Locked
        && unlocktimeInSeconds < investment.unlockDate){
            revert("Unloack date should be grater");
        }
        
        IERC20 token = IERC20(tokenContractAddress);        

        bool tokenTranferStatus = token.transferFrom(msg.sender, address(this), tokenAmount);

        if (!tokenTranferStatus){
            revert("token transfer failed");
        }

        investment.amountStatus = EAmountStatus.Locked;
        investment.userAddress = msg.sender;
        investment.tokenAddress = tokenContractAddress;
        investment.lockAmount = investment.lockAmount.add(tokenAmount);
        investment.amountType = EAmountType.ERC20;
        investment.unlockDate = unlocktimeInSeconds;
        investment.lockDate = getDateTimeNowInSeconds();

       return updateInvestment(investment, uniqueKey);
    }

    function tokenWithdrawal(address tokenContractAddress) external returns (Investment memory){
        bytes32 uniqueKey = getPrivateUniqueKey(tokenContractAddress, msg.sender);

        Investment memory investment = getInvestment(uniqueKey);

        if(investment.amountStatus != EAmountStatus.Locked){
            revert("Investment id not locked");
        }

        if (getDateTimeNowInSeconds() < investment.unlockDate){
            revert(string(abi.encodePacked( "Amount in locked till ", investment.unlockDate)));
        }
        
        if (investment.lockAmount <= 0){
            revert("Amount is 0");
        }
    
        IERC20 token = IERC20(tokenContractAddress);

        bool tokenTranferStatus = token.transfer(msg.sender, investment.lockAmount);

        if (!tokenTranferStatus){
            revert("token transfer failed");
        }

        investment.amountStatus = EAmountStatus.Unlocked;
        investment.lockAmount = 0;

        return updateInvestment(investment, uniqueKey);
    }

    function approveAmount(address tokenContractAddress, uint256 amount) external returns (bool){
         IERC20 token = IERC20(tokenContractAddress);

         return token.approve(msg.sender, amount);
    }

    //currency unique key
    function getPrivateUniqueKey(address userAddress) private pure returns (bytes32){        
        return keccak256(abi.encodePacked( userAddress));
    }

    function currencyInvestment(uint256 lockTimeInSeconds) external payable returns (Investment memory){
        bytes32 uniqueKey = getPrivateUniqueKey(msg.sender);

        Investment memory investment = getInvestment(uniqueKey);

        if(msg.value <= 0){
            revert("amount should be greater than 0.");
        }

        uint256 unlocktimeInSeconds = getDateTimeNowInSeconds().add(lockTimeInSeconds);

        if (investment.amountStatus == EAmountStatus.Locked
        && unlocktimeInSeconds < investment.unlockDate){
            revert("Unlock date should be grater");
        }

        investment.amountStatus = EAmountStatus.Locked;
        investment.userAddress = msg.sender;
        investment.lockAmount = investment.lockAmount.add(msg.value);
        investment.amountType = EAmountType.Coin; 
        investment.unlockDate = unlocktimeInSeconds;
        investment.lockDate = getDateTimeNowInSeconds();

        return updateInvestment(investment, uniqueKey);        
    }

    function currencyWithdrawal() external returns (Investment memory){
        bytes32 uniqueKey = getPrivateUniqueKey(msg.sender);

        Investment memory investment = getInvestment(uniqueKey);

        if(investment.amountStatus != EAmountStatus.Locked){
            revert("Investment id not locked");
        }

        if (getDateTimeNowInSeconds() < investment.unlockDate){
            revert(string(abi.encodePacked( "Amount in locked till ", investment.unlockDate)));
        }
        
        if (investment.lockAmount <= 0){
            revert("Amount is 0");
        }
    
        payable(msg.sender).transfer(investment.lockAmount);

        investment.amountStatus = EAmountStatus.Unlocked;
        investment.lockAmount = 0;

        return updateInvestment(investment, uniqueKey);        
    }

    //Common functions

    function getTokenInvestment(address contractAddress, address userAddress) public view returns (Investment memory){
        bytes32 uniqueKey = getPrivateUniqueKey(contractAddress ,userAddress);

        return investments[uniqueKey];
    }   

    function getcurrencyInvestment(address userAddress) public view returns (Investment memory){
        bytes32 uniqueKey = getPrivateUniqueKey(userAddress);

        return investments[uniqueKey];
    } 

    function getDateTimeNowInSeconds() private view returns (uint256){
        return block.timestamp;
    }
}