/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Synchron{
    /**
    * @notice Administrator for this contract
    */
    address public admin;
    /**
    * @notice Active brains of Knowhere
    */
    address public comptrollerImplementation;

    /**
    * @notice Pending brains of Knowhere
    */
    address public pendingComptrollerImplementation;
}

contract SynchronV1 is Synchron{

    enum OptionType{
        FIXED_OPTION,
        AUCTION_OPTION
    }

    enum OptionState{
        SOLDING,
        SALED,
        CANCELED,
        NUL
    }

    enum OfferState{
        EFFECTIVE,
        INVALID   
    }

    struct OptionParam{ 
        OptionType optionType;
        address token;
        uint256 identifier;
        uint256 amount;
        address creator;
        uint256 singlePrice;
        uint256 expectPrice;
        uint256 startTime;
        uint256 endTime;
    }

    //["0","0xaFd430d2e5f083Ef37f0cf8518Fa79E2d507a344","1002","1","0x3024a5c0870dde2b65ddDd1BFC139f94941EDCAC","100000","0","0","1659074400"]

    struct Option{
        OptionParam optionParam;
        OptionState state;
    }

    struct OfferParam{
        address bidder;
        uint256 price;
    }

    struct Offer{
        OfferParam offerParam;
        OfferState state;
    }

    mapping(uint256 => Option) public optionInfo;
    mapping(uint256 => Offer) public offerInfo;
    mapping(uint256 => uint) offerIndex;

    mapping(uint256 => uint256[]) optionCorrespondingOffer;
    mapping(uint256 => uint256) public offerCorrespondingOption;

    uint256 public initOptionNumber;

    uint256 public initOfferNumber;
    /**
    * @notice Royalty management contract
    */
    address royaltyManager;
    /**
    * @notice WETH contract address
    */
    address public WETH;
    // /**
    // * @notice Nft transfer selector address
    // */
    // address transferSelector;
    // /**
    // * @notice Market fee receiving address
    // */
    address public marketFeeRecipient;
    /**
    * @notice Fixed price order exchange rate
    */
    uint256 public marketFeeToFixed;
    /**
    * @notice Auction option exchange rate
    */
    uint256 public marketFeeToAuction;
    /**
    * @notice IERC1155 protocol support switch
    */
    bool    public isAuctionSupport1155;

}


contract KnowhereProxy is Synchron{

    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    event NewImplementation(address oldImplementation, address newImplementation);
    /**
      * @notice Emitted when pendingAdmin is accepted, which means admin is updated
      */
    event NewAdmin(address oldAdmin, address newAdmin);

    receive() external payable {
        //assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    constructor() {
        // Set admin to caller
        admin = msg.sender;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) public  {
        
        require(admin == msg.sender,"KnowhereProxy:not permit");

        address oldPendingImplementation = pendingComptrollerImplementation;

        pendingComptrollerImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingComptrollerImplementation);

    }

    function _acceptImplementation() public returns(uint){

        require(pendingComptrollerImplementation == msg.sender && pendingComptrollerImplementation != address(0));

        // Save current values for inclusion in log
        address oldImplementation = comptrollerImplementation;
        address oldPendingImplementation = pendingComptrollerImplementation;

        comptrollerImplementation = pendingComptrollerImplementation;

        pendingComptrollerImplementation = address(0);

        emit NewImplementation(oldImplementation, comptrollerImplementation);

        emit NewPendingImplementation(oldPendingImplementation, pendingComptrollerImplementation);

        return 0;
    }

    function _updateAdmin(address _admin) public {
        require(admin == msg.sender,"KnowhereProxy:not permit");
        admin = _admin;
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    fallback() payable external {
        // delegate all other functions to current implementation
        (bool success, ) = comptrollerImplementation.delegatecall(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize())

              switch success
              case 0 { revert(free_mem_ptr, returndatasize()) }
              default { return(free_mem_ptr, returndatasize()) }
        }
    }

}

//WETH:0x6aB841824ef370601dB48197C334217F7f5E4439
//actuator:0xccb5f729d68e7DaC72210993fFb307AedA7244De
//proxy:0xb7A6Da0c3d333bfc783006bC7D39F0F77e0bBaa3
//721:0xE1ce8c61f1dF3fCc9e805c2d0ad94995a3904e5c
//1155:0xaE98D8C69C7B61Ba772570c536dCaF379d2B0336