// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.


// This contract generates Token01 contracts and registers them in the TokenFactory.
// Ideally you should not interact with this contract directly, and use the Unicrypt token app instead so warnings can be shown where necessary.

pragma solidity 0.8.17;


import "./IERC20.sol";
import "./Ownable.sol";

import "./TaxToken.sol";

import "./IMintFactory.sol";
import "./IFeeHelper.sol";

contract MintGenerator is Ownable {
    
    uint256 public CONTRACT_VERSION = 1;


    IMintFactory public MINT_FACTORY;
    IFeeHelper public FEE_HELPER;
    
    constructor(address _mintFactory, address _feeHelper) {
        MINT_FACTORY = IMintFactory(_mintFactory);
        FEE_HELPER = IFeeHelper(_feeHelper);
    }
    
    /**
     * @notice Creates a new Token contract and registers it in the TokenFactory.sol.
     */
    
    function createToken (
      TaxToken.ConstructorParams calldata params
      ) public payable returns (address){
        require(msg.value == FEE_HELPER.getGeneratorFee(), 'FEE NOT MET');
        payable(FEE_HELPER.getFeeAddress()).transfer(FEE_HELPER.getGeneratorFee());
        TaxToken newToken = new TaxToken(params, address(MINT_FACTORY));
        MINT_FACTORY.registerToken(msg.sender, address(newToken));
        return address(newToken);
    }
}