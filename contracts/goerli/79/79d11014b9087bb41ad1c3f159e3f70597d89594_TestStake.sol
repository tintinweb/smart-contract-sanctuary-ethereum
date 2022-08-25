/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// File: contracts/ISwell.sol



pragma solidity >=0.7.0 <0.9.0;

      struct Stake {
        bytes pubKey;
        bytes signature;
        bytes32 depositDataRoot;
        uint256 amount;
    }
interface ISwell {  


// function stake(Stake[] calldata stakes, string calldata referral) external payable whenNotPaused returns (uint256[] memory ids)
    function stake (Stake[] calldata stakes, string  calldata referral) external payable returns (uint256[] memory ids);
}


// File: contracts/TestStake.sol



pragma solidity >=0.7.0 <0.9.0;

// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


// contract TestStake is ReentrancyGuard{
  contract TestStake {

   /**
   * @notice contracts address constants,constructor 
   */

    ISwell  public iSwell;
    address constant public swellContractAddress= 0x23e33FC2704Bb332C0410B006e8016E7B99CF70A ;
    // address constant public swellContractAddress= 0xF7216B7a4405c0179A0b94b358B270c3DBA38E33 ;

    constructor()  {
          iSwell = ISwell(swellContractAddress) ;
    }
    
      function swellStakeEth ( Stake[] calldata stakes , string calldata referral) external payable   {
        iSwell.stake{ value : msg.value }( stakes , referral) ;
        // swellContractAddress.call{value : msg.value}(abi.encodeWithSignature("stake((tuple[] ,string)", _stakes, _referral ));
      //  swellContractAddress.call{value : msg.value}(abi.encodeWithSignature("stake((Stake[] ,string)", _stakes, _referral ));
    }
}