/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Lido_Shuffle {
    address TRIBE_Treasury;
    ILido Lido_stETH;
    
    constructor() {
        TRIBE_Treasury = 0x7E3Ee99EC9b2aBd42c8c8504dc8195C8dc4942D0; // currently MY Goerli addy - will be the Tribe treasury address
        //I AM THE TRIBE
        Lido_stETH = ILido(0x1D29643500b7FdB575C8f378cAE13f614ed6956e); // an StETH address I found on rinkeby - speedread the code and its pretty much golden
    }

    // modifier to check if caller is the Tribe DAO or not
    modifier isTribeDAO() {
        require(msg.sender == TRIBE_Treasury, "You aren't part of the tribe...");
        _;
    }

    function getSTETH() public payable isTribeDAO {
       //  main.handlePayment{value:(msg.value)}
       Lido_stETH.submit{value:(msg.value)}(address(this));
    }
}

interface ILido {
    /**
      * @notice Adds eth to the pool
      * @return StETH Amount of StETH generated
      */
    function submit(address _referral) external payable returns (uint256 StETH);
}