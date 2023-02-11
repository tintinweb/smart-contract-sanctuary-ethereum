// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "../libraries/LibCommunicationProfileDiamond.sol";

contract ReadCommunicationProfileFacet {
    function getMNOCommunicationProfileTitle()
        external
        view
        returns (string memory)
    {
        return LibCommunicationProfileDiamond.getMNOCommunicationProfileTitle();
    }

    function getMNOCommunicationProfile()
        external
        pure
        returns (LibCommunicationProfileDiamond.MNOCommunicationProfile memory)
    {
        return
            LibCommunicationProfileDiamond.getMNOCommunicationProfileStorage();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Library Storage
 * @dev In library we can declear only constant state varialbes. Arrays are also needed to be decleared with default values.
 */

library LibCommunicationProfileDiamond {

    // --------------> Storage Layout: Start <--------------
    bytes32 internal constant MNO_COMMUNICATION_PROFILE_POSITION =
        keccak256("communication.profile.facet"); // Namespace

    struct MNOCommunicationProfile {
        uint id;
        string title;
        string iccid;
        string msisdn;
        string imsi;
    }

    // --------------> Storage Layout: End <--------------

    function getMNOCommunicationProfileStorage()
        internal
        pure
        returns (MNOCommunicationProfile storage s)
    {
        bytes32 position = MNO_COMMUNICATION_PROFILE_POSITION;
        assembly {
            // A computer may have only two registers but around 16,000 slots in memory.
            // This is just returning the slot position.
            s.slot := position
        }
    }

    function setMNOCommunicationProfile(
        string calldata _title,
        string calldata _iccid,
        string calldata _msisdn,
        string calldata _imsi
    ) internal {
        MNOCommunicationProfile storage mcp = getMNOCommunicationProfileStorage();
        mcp.id = 1;
        mcp.title = _title;
        mcp.iccid = _iccid;
        mcp.msisdn = _msisdn;
        mcp.imsi = _imsi;
    }

    function getMNOCommunicationProfileTitle()
        internal
        view
        returns (string memory)
    {
        return getMNOCommunicationProfileStorage().title;
    }
/******************************************************************************\
* Author: Md. Ariful Islam <[email protected]> (https://www.linkedin.com/in/engr-arif/)
* Why using a Library with the collections of internal functions?
* => If we keep internal and external both type of functions in a Library it will have its own contract address.
    But if the library holds only internal functions it will become part of the ByteCode in what ever facets we include in.
    Library contains view-only functions that may be common to multiple consumer contracts and help avoid redundancy. It is a
    standalone entity that looks similar to a contract but brings gas efficiency in the system.
    
    Data Location: 
        # Storage:
            - Directly located in Blockchain ​
            - High Gas Cost​
            - If any reference type variable gets updated in storage type at
            local level it will get updated in the state variable level also.  
        # Memory:
            - Get temporary stored at RAM/Stack​
            - Memory type cannot pass as an argument to a Calldata parameter​
            - Low Gas Cost (Ignorable Gas Cost)​
            - Function input / return and local variables uses Memory
        # Calldata:
            - Gets temporary stored at RAM/Stack​
            - Low Gas Cost ​
            - Calldata  data can be passed at Memory/Calldata both ​
            - Stored data is unchangeable ​
            - If same callback data is used in two different functions as argument 
            both of the function will use the same  reference of that  value. 
            This is how we can save the Gas cost
/******************************************************************************/
}