// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./../interfaces/IFigurePrintOracle.sol";

contract UserIdentityNFT {
    using Counters for Counters.Counter;
    Counters.Counter private idCount;
    address private figureprintOracle;
    bytes32 public constant CLAME_USERID_VOUCHER =
        keccak256("createUserId(string uri,bytes userId,bytes fingerPrint)");
    // SPDX-License-Identifier: UNLICENSED

    struct UserIdVoucher {
        /// @notice The metadata URI to associate with this token.
        string uri;
        /// @notice Minimum price of the nft.
        bytes userId;
        /// @notice True if and only if fixed price mode.
        bytes fingerPrint;
        /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
        bytes signature;
    }
    error UserIdentityNFT__FirstVerifyIdenetity();

    event IdVerifedAndIssued(bytes indexed userId, address userAddres, VerficationStatus);

    // "NFTVoucher(uint256 tokenId,string uri,address currency,uint256 minPrice,bool isFixedPrice)"

    constructor(address _figureprintOracle) {
        figureprintOracle = _figureprintOracle;
    }

    function verifyFingerPrint(bytes memory userId, bytes memory fingerPrint) public {
        IFigurePrintOracle(figureprintOracle).verifyFingerPrint(msg.sender, userId, fingerPrint);
        //check user balance if it is one not allow to verify new ID
        // first we call here connect with oricel contract to send request for vaification of the data
    }

    /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.

    function redeem(UserIdVoucher calldata voucher) public {
        // super._mint(to, tokenId);
        // get user id and get which token id assign to that user and what is the status of signature

        // bool userRecord = IFigurePrintOracle(figureprintOracle).getUserVerification(msg.sender);
        revert UserIdentityNFT__FirstVerifyIdenetity();

        if (true) {
            revert UserIdentityNFT__FirstVerifyIdenetity();
        }

        bytes memory b = new bytes(0);
        emit IdVerifedAndIssued(b, msg.sender, VerficationStatus.PENDING);
        // } else if (userRecord.status == VerficationStatus.PENDING) {
        //     revert UserIdentityNFT__VerficationStillPending();
        // } else if (userRecord.status == VerficationStatus.FAIL) {
        //     revert UserIdentityNFT__VerficationStillFail();
        // }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "./../libraries/OracleHelper.sol";

interface IFigurePrintOracle {
    //Events
    event VerifyFingerPrint(bytes indexed userId, bytes32 requestId, address userAddress);
    event VerifationResponse(
        address indexed userAddress,
        bytes32 indexed requestId,
        string isVerfied
    );
    event ReceivedCalled(address indexed buyer, uint256 indexed amount);
    event FallbackCalled(address indexed buyer, uint256 indexed amount);
    event WithDrawAmount(address indexed buyer, uint256 indexed amount);

    // Error
    error FigurePrintOracle__RequestAlreadyExist(address userAddress);
    error FigurePrintOracle__VerficationAlreadyDone(address userAddress);
    error FigurePrintOracle__ExceedNumberTries(address userAddress);
    error FigurePrintOracle__NotVerifer();
    error FigurePrintOracle__NoAmountForWithDraw();
    error FigurePrintOracle__FailToWithDrawAmount();

    function verifyFingerPrint(
        address userAddress,
        bytes calldata userId,
        bytes calldata fingerPrint
    ) external;

    function withdrawLink() external payable;

    function getUserRecord(address userAddress) external returns (VerifcaitonRecord calldata);

    function getUserVerification(address userAddress) external returns (bool);

    function setChainLinkToken(address linkToken) external;

    function setChainLinkOracle(address oricle) external;

    function setJobId(bytes32 _jobId) external;

    function setFee(uint256 _fee) external;

    function setVeriferRole(address verifer) external;

    function burnUserRecord(address userAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
struct VerifcaitonRecord {
    bytes userId;
    uint numberTries; //no more the 3 request if case of Rejection
    VerficationStatus status; //
}

enum VerficationStatus {
    DEAFULT, // because when check record is pending even it don't exist status will be zero
    PENDING,
    VERIFIED,
    FAIL
}