/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
      function balanceOf(address account) external view returns (uint256);
  
}



contract ProofOfPaperHandsTracker {

    mapping (address => bool) private _isPaperHanded;
    mapping (address => bool) private _isBot;
    event PaperHands(address indexed account);
    event Bot(address indexed account);
    address[] public _paperHanded;
    address[] public _bot;

    IERC20 public POPH = IERC20(0x1791a788598828073d7c7Ff52B1da5f27E962064);
    uint256 constant minBalance = 100 * 10**18;

 
    function submitPaperHands(address account) public{
        uint256 POPHCheck = POPH.balanceOf(address(msg.sender));
        require(POPHCheck >= minBalance, "Must Hold 100 POPH");
        require(!_isPaperHanded[account] , "Account Already Submitted");
        require(!_isBot[account] , "Account Already Submitted");
        _isPaperHanded[account] = true ;
        _paperHanded.push(account);
  
       emit PaperHands(account);
    }

    function submitBot(address account) public{
        uint256 POPHCheck = POPH.balanceOf(address(msg.sender));
        require(POPHCheck >= minBalance, "Must Hold 100 POPH");
        require(!_isBot[account] , "Account Already Submitted");
        require(!_isPaperHanded[account] , "Account Already Submitted");
        _isBot[account] = true ;
        _bot.push(account);
  
       emit Bot(account);
    }

     function getCountOfPaperHands() external view returns (uint256) {
		return _paperHanded.length;
	}

     function getCountOfBots() external view returns (uint256) {
		return _bot.length;
	}   
    
    function IsPaperHands (address account) public view returns (bool) {
       
        return _isPaperHanded[account];

    }

    function IsBots (address account) public view returns (bool) {
       
        return _isBot[account];

    }
}