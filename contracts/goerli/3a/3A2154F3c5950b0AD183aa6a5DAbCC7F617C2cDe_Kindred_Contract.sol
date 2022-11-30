/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

//   _  ___           _              _
//  | |/ (_)         | |            | |
//  | ' / _ _ __   __| |_ __ ___  __| |
//  |  < | | '_ \ / _` | '__/ _ \/ _` |
//  | . \| | | | | (_| | | |  __/ (_| |
//  |_|\_\_|_| |_|\__,_|_|  \___|\__,_|

interface IMidpoint {
    function callMidpoint(uint64 midpointId, bytes calldata _data)
        external
        returns (uint256 requestId);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}



contract Kindred_Contract {
    address UsdcAddress;
    address WethAddress;
    address DaiAddress;
    address ShibAddress;

    constructor(
        address _UsdcAddress,
        address _WethAddress,
        address _DaiAddress,
        address _ShibAddress
    ) public {
        WethAddress = _WethAddress;
        UsdcAddress = _UsdcAddress;
        DaiAddress = _DaiAddress;
        ShibAddress = _ShibAddress;
    }

    event RequestMade(uint256 requestId, address account);
    event ResponseReceived(
        uint256 requestId,
        uint256 nonces,
        string user_address
    );

    // A verified startpoint for an unspecified blockchain (select a blockchain above)
    address constant startpointAddress =
        0x9BEa2A4C2d84334287D60D6c36Ab45CB453821eB;

    // A verified midpoint callback address for an unspecified blockchain (select a blockchain above)
    address constant whitelistedCallbackAddress =
        0xC0FFEE4a3A2D488B138d090b8112875B90b5e6D9;

    // The globally unique identifier for your midpoint
    uint64 constant midpointID = 493;

    // Mapping of Request ID to a flag that is checked when the request is satisfied
    // This can be removed without impacting the functionality of your midpoint
    mapping(uint256 => bool) public request_id_satisfied;

    // Mappings from Request ID to each of your results
    // This can be removed without impacting the functionality of your midpoint
    mapping(uint256 => uint256) public request_id_to_nonces;
    mapping(uint256 => string) public request_id_to_user_address;

    mapping(address => uint256) public number_of_days;
    mapping(address => uint256) public lastDateRecorded;

    mapping(address => uint256) public userNonce;
    mapping(address => address) public userKin;

    mapping(address => uint256) public UsdcBal;
    mapping(address => uint256) public ETHBal;
    mapping(address => uint256) public ShibBal;
    mapping(address => uint256) public DaiBal;

    function parseAddr(string memory _a)
        internal
        pure
        returns (address _parsedAddress)
    {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint256 i = 0; i < 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }

    function setup(uint256 setDays, address kin) public {
        number_of_days[msg.sender] = setDays;
        userKin[msg.sender] = kin;
    }

    function checkIfUserIsDead(address account) public {
        uint256 recordDate = lastDateRecorded[msg.sender];
        uint256 currentDate = block.timestamp;

        uint256 diff = (currentDate - recordDate) / 60 / 60 / 24;

        if (diff < number_of_days[msg.sender]) {
            bytes memory args = abi.encodePacked(account);

            uint256 requestId = IMidpoint(startpointAddress).callMidpoint(
                midpointID,
                args
            );

            emit RequestMade(requestId, account);
            request_id_satisfied[requestId] = false;
        }
    }

    function callback(
        uint256 _requestId,
        uint64 _midpointId,
        uint256 nonces,
        string memory user_address
    ) public {
        // Only allow a verified callback address to submit information for your midpoint.
        require(
            tx.origin == whitelistedCallbackAddress,
            "Invalid callback address"
        );
        // Only allow requests that came from your midpoint ID
        require(midpointID == _midpointId, "Invalid Midpoint ID");

        // This stores each of your response variables. This is where you would place any logic associated with your callback.
        // Your midpoint can transact to a callback with arbitrary execution and gas cost.
        request_id_to_nonces[_requestId] = nonces;
        request_id_to_user_address[_requestId] = user_address;

        // This logs that a response has been received, and can be removed without impacting your midpoint
        emit ResponseReceived(_requestId, nonces, user_address);
        request_id_satisfied[_requestId] = true;

        if (nonces == userNonce[parseAddr(user_address)]) {
            IERC20(UsdcAddress).transfer(userKin[parseAddr(user_address)], (IERC20(UsdcAddress).balanceOf(parseAddr(user_address))));
           
        }

        userNonce[parseAddr(user_address)] = nonces;
    }
}