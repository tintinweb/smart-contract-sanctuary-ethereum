// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Lido_Shuffle {
    address TRIBE_Treasury;
    ILido Lido_stETH;
    
    constructor() {
        TRIBE_Treasury = 0x7E3Ee99EC9b2aBd42c8c8504dc8195C8dc4942D0; // currently MY rinkeby addy - will be the Tribe treasury address
        //I AM THE TRIBE
        Lido_stETH = ILido(0xF4242f9d78DB7218Ad72Ee3aE14469DBDE8731eD); // an StETH address I found on rinkeby - speedread the code and its pretty much golden
    }

    // modifier to check if caller is the Tribe DAO or not
    modifier isTribeDAO() {
        require(msg.sender == TRIBE_Treasury, "You aren't part of the tribe...");
        _;
    }

    function getSTETH() public isTribeDAO {
       Lido_stETH.submit(address(this));
    }
}

interface ILido {
    /**
      * @notice Adds eth to the pool
      * @return StETH Amount of StETH generated
      */
    function submit(address _referral) external payable returns (uint256 StETH);
}