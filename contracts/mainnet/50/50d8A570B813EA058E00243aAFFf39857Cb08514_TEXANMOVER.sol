/// SPDX-License-Identifier: UNLICENCSED
/// @title Airdrop Token Mover
/// @author Aidrop Mover Team
/// @notice This contract is proprietary and may not be copied or used without permission.

pragma solidity ^0.8.17;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

import "./IERC20.sol";
import "./Ownable.sol";

contract TEXANMOVER is Ownable {
    IERC20 _token;


    uint tokensTransferredIn = 0;
    string otherthings = "";
    uint public lastBatch = 0; 

    uint _errorCount = 0;
    uint _successCount = 0;
    
    address _zeroAddress = 0x0000000000000000000000000000000000000000;
    address tokenAddress = _zeroAddress;  //initialize with this

    struct Airdropitem { 
        uint batch;
        address user_address;
        string message;
        uint processed;
    }

    Airdropitem[] _airdropitems;
    
    // @notice This contract has the utilities necessary for the Staking Endowment Token below
    event BulkTransfer(
        uint batch,
        address indexed from,  // Address
        address indexed to,
        uint256 indexed amount
    );

    event BatchStatus ( 
        uint batch,
        uint totalInBatch,
        uint successCount,
        uint errorCount
    );


    // token = MyToken's contract address
    constructor(address token) {
        tokenAddress = token;
        _token = IERC20(token);
    }

    // Modifier to check token allowance
    modifier checkAllowance(uint amount) {
        require(_token.allowance(msg.sender, address(this)) >= amount, "Error24");
        _;
    }
    
    function setToken(address token) external onlyOwner {
        tokenAddress = token;
        _token = IERC20(token);
    }
    
    function showToken() external view returns(address myTokenAddress){
        return (tokenAddress);
    }
    
    function showToken2() external view returns(address myTokenAddress){
        return (address(_token));
    }


    function airdrop(address holder, uint256 amount) public onlyOwner {
        uint batch = 0;
        Airdropitem memory myTok;
        
            try _token.transfer(holder, amount) {
                // if successful, this will ring true and continue
                _successCount = _successCount + 1;

            } catch Error(string memory reason) {
                // This is executed in case
                // revert was called inside getData
                // and a reason string was provided.
                 myTok = Airdropitem(batch, holder, reason, 0);
                 _airdropitems.push(myTok);

                _errorCount++;
                
            } catch (bytes memory mylowlevelreason) {
                // This is executed in case revert() was used
                // or there was a failing assertion, division
                // by zero, etc. inside getData.
                 myTok = Airdropitem(batch, holder, string(mylowlevelreason), 0);
                 _airdropitems.push(myTok);

                _errorCount++;
                
            }
    }


    function airdropMany(uint batch, address[] memory holders, uint[] memory holderamounts) public onlyOwner {
        require(holders.length == holderamounts.length, "Holders and HolderAmounts must have the same number of entries.");
        require(address(_token) != _zeroAddress,"Stop! Do not airdrop to zero address");

        Airdropitem memory myTok;
        
        uint total_in_batch = holders.length;
        uint local_success = 0;
        uint local_error = 0;

        for (uint i=0; i<holders.length; i++) {
            
            try _token.transfer(holders[i], uint(holderamounts[i])) {
                // if successful, this will ring true and continue
                _successCount = _successCount + 1;
                local_success++;

                emit BulkTransfer(batch, address(_token), holders[i], holderamounts[i]);

            } catch Error(string memory reason) {
                // This is executed in case
                // revert was called inside getData
                // and a reason string was provided.
                 myTok = Airdropitem(batch, holders[i], reason, holderamounts[i]);
                 _airdropitems.push(myTok);
                local_error++;
                _errorCount++;
                
            } catch (bytes memory mylowlevelreason) {
                // This is executed in case revert() was used
                // or there was a failing assertion, division
                // by zero, etc. inside getData.
                 myTok = Airdropitem(batch, holders[i], string(mylowlevelreason), holderamounts[i]);
                 _airdropitems.push(myTok);

                _errorCount++;
                local_error++;
                
            }
            // Set the last batch to the current one


            // emit Transfer(address(this), holders[i], amount);
        }
        
        lastBatch = batch;
        emit BatchStatus(batch, total_in_batch, local_success, local_error);

    }


    // Allow you to show how many tokens does this smart contract own
    function getSmartContractBalance() external view returns(uint) {
        return _token.balanceOf(payable(address(this)));
    }
    
    // --------------
    function differenceTest(uint valA, uint valB) public pure returns(uint mydifference){
        // Gets the difference either way
        if(valA > valB){
            mydifference = valA - valB;
        } else if (valB > valA) {
            mydifference = valA - valB;
        } else {
            // If neither are larger, then return zero
            mydifference = 0;
        }
        return (mydifference);
    }
    // --------------
    function addTest(uint valA, uint valB) public pure returns(uint myAnswer){
        // Gets the difference either way
        myAnswer = valA + valB;
        return (myAnswer);
    }

    

function fund() public payable returns(bool success) {
    // Do not use this...ever
}

function showStatistics() external view returns(uint successCount, uint errorCount ){

        return (_successCount,_errorCount);
}


function countAirdropitems()
    external
    view
    returns (
        uint256
    )
    {
        return _airdropitems.length;
    }

function unsetMainContract() external onlyOwner {
    _successCount = 0;
    _errorCount = 0;
    tokenAddress = _zeroAddress;
    delete _token;
}

function getAirdropitems() external view onlyOwner returns( Airdropitem[] memory){
    return (_airdropitems);
}

function popAirdropitems(uint airdropitemIndex) public onlyOwner(){
        // Airdropitem[] _airdropitems;
        // Remove the Stake from your stake list
        require(_airdropitems.length > 0,"Nothing to do, array is empty");
        require(airdropitemIndex <= _airdropitems.length, "That index is too large.");

        uint256 lastIndex = _airdropitems.length - 1;
        // If it's the last element, then skip
        if (airdropitemIndex != lastIndex) {
            _airdropitems[airdropitemIndex] = _airdropitems[lastIndex];
        }
        _airdropitems.pop();
    }


}