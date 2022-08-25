/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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




contract TestStake is ReentrancyGuard{
   /**
   * @notice contracts address constants,constructor 
   */

    ISwell  public iSwell;
    address constant public swellContractAddress= 0x23e33FC2704Bb332C0410B006e8016E7B99CF70A ;
    // address constant public swellContractAddress= 0xF7216B7a4405c0179A0b94b358B270c3DBA38E33 ;

    constructor()  {
          iSwell = ISwell(swellContractAddress) ;
    }
    
      function swellStakeEth ( Stake[] calldata _stakes , string calldata _referral) external payable   {
        iSwell.stake{ value : msg.value }( _stakes , _referral) ;
        // swellContractAddress.call{value : msg.value}(abi.encodeWithSignature("stake((tuple[] ,string)", _stakes, _referral ));
      //  swellContractAddress.call{value : msg.value}(abi.encodeWithSignature("stake((Stake[] ,string)", _stakes, _referral ));
    }
}