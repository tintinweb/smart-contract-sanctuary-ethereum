// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

interface IGombocController {
    struct Point {
        uint256 bias;
        uint256 slope;
    }

    struct VotedSlope {
        uint256 slope;
        uint256 power;
        uint256 end;
    }

    struct UserPoint {
        uint256 bias;
        uint256 slope;
        uint256 ts;
        uint256 blk;
    }

    event AddType(string name, int128 type_id);

    event NewTypeWeight(int128 indexed type_id, uint256 time, uint256 weight, uint256 total_weight);

    event NewGombocWeight(address indexed gomboc_address, uint256 time, uint256 weight, uint256 total_weight);

    event VoteForGomboc(address indexed user, address indexed gomboc_address, uint256 time, uint256 weight);

    event NewGomboc(address indexed gomboc_address, int128 gomboc_type, uint256 weight);

    /**
     * @notice Get gomboc type for address
     *  @param _addr Gomboc address
     * @return Gomboc type id
     */
    function gombocTypes(address _addr) external view returns (int128);

    /**
     * @notice Add gomboc `addr` of type `gomboc_type` with weight `weight`
     * @param addr Gomboc address
     * @param gombocType Gomboc type
     * @param weight Gomboc weight
     */
    function addGomboc(address addr, int128 gombocType, uint256 weight) external;

    /**
     * @notice Checkpoint to fill data common for all gombocs
     */
    function checkpoint() external;

    /**
     * @notice Checkpoint to fill data for both a specific gomboc and common for all gomboc
     * @param addr Gomboc address
     */
    function checkpointGomboc(address addr) external;

    /**
     * @notice Get Gomboc relative weight (not more than 1.0) normalized to 1e18(e.g. 1.0 == 1e18). Inflation which will be received by
     * it is inflation_rate * relative_weight / 1e18
     * @param gombocAddress Gomboc address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gombocRelativeWeight(address gombocAddress, uint256 time) external view returns (uint256);

    /**
     *  @notice Get gomboc weight normalized to 1e18 and also fill all the unfilled values for type and gauge records
     * @dev Any address can call, however nothing is recorded if the values are filled already
     * @param gombocAddress Gomboc address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gombocRelativeWeightWrite(address gombocAddress, uint256 time) external returns (uint256);

    /**
     * @notice Add gomboc type with name `_name` and weight `weight`
     * @dev only owner call
     * @param _name Name of gauge type
     * @param weight Weight of gauge type
     */
    function addType(string memory _name, uint256 weight) external;

    /**
     * @notice Change gomboc type `type_id` weight to `weight`
     * @dev only owner call
     * @param type_id Gomboc type id
     * @param weight New Gomboc weight
     */
    function changeTypeWeight(int128 type_id, uint256 weight) external;

    /**
     * @notice Change weight of gomboc `addr` to `weight`
     * @param gombocAddress `Gomboc` contract address
     * @param weight New Gomboc weight
     */
    function changeGombocWeight(address gombocAddress, uint256 weight) external;

    /**
     * @notice Allocate voting power for changing pool weights
     * @param gombocAddress Gomboc which `msg.sender` votes for
     * @param userWeight Weight for a gomboc in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0.
     *        example: 10%=1000,3%=300,0.01%=1,100%=10000
     */
    function voteForGombocWeights(address gombocAddress, uint256 userWeight) external;

    /**
     * @notice Get current gomboc weight
     * @param addr Gomboc address
     * @return Gomboc weight
     */

    function getGombocWeight(address addr) external view returns (uint256);

    /**
     * @notice Get current type weight
     * @param type_id Type id
     * @return Type weight
     */
    function getTypeWeight(int128 type_id) external view returns (uint256);

    /**
     * @notice Get current total (type-weighted) weight
     * @return Total weight
     */
    function getTotalWeight() external view returns (uint256);

    /**
     * @notice Get sum of gomboc weights per type
     * @param type_id Type id
     * @return Sum of gomboc weights
     */
    function getWeightsSumPreType(int128 type_id) external view returns (uint256);

    function votingEscrow() external view returns (address);
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

interface ILT {
    /**
     * @dev Emitted when LT inflation rate update
     *
     * Note once a year
     */
    event UpdateMiningParameters(uint256 time, uint256 rate, uint256 supply);

    /**
     * @dev Emitted when set LT minter,can set the minter only once, at creation
     */
    event SetMinter(address indexed minter);

    function rate() external view returns (uint256);

    /**
     * @notice Update mining rate and supply at the start of the epoch
     * @dev   Callable by any address, but only once per epoch
     *        Total supply becomes slightly larger if this function is called late
     */
    function updateMiningParameters() external;

    /**
     * @notice Get timestamp of the next mining epoch start while simultaneously updating mining parameters
     * @return Timestamp of the next epoch
     */
    function futureEpochTimeWrite() external returns (uint256);

    /**
     * @notice Current number of tokens in existence (claimed or unclaimed)
     */
    function availableSupply() external view returns (uint256);

    /**
     * @notice How much supply is mintable from start timestamp till end timestamp
     * @param start Start of the time interval (timestamp)
     * @param end End of the time interval (timestamp)
     * @return Tokens mintable from `start` till `end`
     */
    function mintableInTimeframe(uint256 start, uint256 end) external view returns (uint256);

    /**
     *  @notice Set the minter address
     *  @dev Only callable once, when minter has not yet been set
     *  @param _minter Address of the minter
     */
    function setMinter(address _minter) external;

    /**
     *  @notice Mint `value` tokens and assign them to `to`
     *   @dev Emits a Transfer event originating from 0x00
     *   @param to The account that will receive the created tokens
     *   @param value The amount that will be created
     *   @return bool success
     */
    function mint(address to, uint256 value) external returns (bool);

    /**
     * @notice Burn `value` tokens belonging to `msg.sender`
     * @dev Emits a Transfer event with a destination of 0x00
     * @param value The amount that will be burned
     * @return bool success
     */
    function burn(uint256 value) external returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "./interfaces/ILT.sol";
import "./interfaces/IGombocController.sol";

interface LiquidityGomboc {
    function integrateFraction(address addr) external view returns (uint256);

    function userCheckpoint(address addr) external returns (bool);
}

contract Minter {
    event Minted(address indexed recipient, address gomboc, uint256 minted);
    event ToogleApproveMint(address sender, address indexed mintingUser, bool status);

    address public immutable token;
    address public immutable controller;

    // user -> gomboc -> value
    mapping(address => mapping(address => uint256)) public minted;

    // minter -> user -> can mint?
    mapping(address => mapping(address => bool)) public allowedToMintFor;

    /*
     * @notice Contract constructor
     * @param _token  LT Token Address
     * @param _controller gomboc Controller Address
     */
    constructor(address _token, address _controller) {
        token = _token;
        controller = _controller;
    }

    /**
     * @notice Mint everything which belongs to `msg.sender` and send to them
     * @param gombocAddress `LiquidityGomboc` address to get mintable amount from
     */
    function mint(address gombocAddress) external {
        _mintFor(gombocAddress, msg.sender);
    }

    /**
     * @notice Mint everything which belongs to `msg.sender` across multiple gombocs
     * @param gombocAddressList List of `LiquidityGomboc` addresses
     */
    function mintMany(address[] memory gombocAddressList) external {
        for (uint256 i = 0; i < gombocAddressList.length && i < 128; i++) {
            if (gombocAddressList[i] == address(0)) {
                continue;
            }
            _mintFor(gombocAddressList[i], msg.sender);
        }
    }

    /**
     * @notice Mint tokens for `_for`
     * @dev Only possible when `msg.sender` has been approved via `toggle_approve_mint`
     * @param gombocAddress `LiquidityGomboc` address to get mintable amount from
     * @param _for Address to mint to
     */
    function mintFor(address gombocAddress, address _for) external {
        if (allowedToMintFor[msg.sender][_for]) {
            _mintFor(gombocAddress, _for);
        }
    }

    /**
     * @notice allow `mintingUser` to mint for `msg.sender`
     * @param mintingUser Address to toggle permission for
     */
    function toggleApproveMint(address mintingUser) external {
        bool flag = allowedToMintFor[mintingUser][msg.sender];
        allowedToMintFor[mintingUser][msg.sender] = !flag;
        emit ToogleApproveMint(msg.sender, mintingUser, !flag);
    }

    function _mintFor(address gombocAddr, address _for) internal {
        ///Gomnoc not adde
        require(IGombocController(controller).gombocTypes(gombocAddr) >= 0, "CE000");

        bool success = LiquidityGomboc(gombocAddr).userCheckpoint(_for);
        require(success, "CHECK FAILED");
        uint256 totalMint = LiquidityGomboc(gombocAddr).integrateFraction(_for);
        uint256 toMint = totalMint - minted[_for][gombocAddr];

        if (toMint != 0) {
            minted[_for][gombocAddr] = totalMint;
            bool success = ILT(token).mint(_for, toMint);
            require(success, "MINT FAILED");
            emit Minted(_for, gombocAddr, toMint);
        }
    }
}