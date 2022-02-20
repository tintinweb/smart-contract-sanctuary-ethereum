/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

/* This contract is a subsidiary of the Hedron contract. The Hedron      *
 *  contract can be found at 0x3819f64f282bf135d62168C1e513280dAF905e06. */

/* Hedron is a collection of Ethereum / PulseChain smart contracts that  *
 * build upon the HEX smart contract to provide additional functionality */

interface IHEX {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Claim(
        uint256 data0,
        uint256 data1,
        bytes20 indexed btcAddr,
        address indexed claimToAddr,
        address indexed referrerAddr
    );
    event ClaimAssist(
        uint256 data0,
        uint256 data1,
        uint256 data2,
        address indexed senderAddr
    );
    event DailyDataUpdate(uint256 data0, address indexed updaterAddr);
    event ShareRateChange(uint256 data0, uint40 indexed stakeId);
    event StakeEnd(
        uint256 data0,
        uint256 data1,
        address indexed stakerAddr,
        uint40 indexed stakeId
    );
    event StakeGoodAccounting(
        uint256 data0,
        uint256 data1,
        address indexed stakerAddr,
        uint40 indexed stakeId,
        address indexed senderAddr
    );
    event StakeStart(
        uint256 data0,
        address indexed stakerAddr,
        uint40 indexed stakeId
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event XfLobbyEnter(
        uint256 data0,
        address indexed memberAddr,
        uint256 indexed entryId,
        address indexed referrerAddr
    );
    event XfLobbyExit(
        uint256 data0,
        address indexed memberAddr,
        uint256 indexed entryId,
        address indexed referrerAddr
    );

    fallback() external payable;

    function allocatedSupply() external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function btcAddressClaim(
        uint256 rawSatoshis,
        bytes32[] memory proof,
        address claimToAddr,
        bytes32 pubKeyX,
        bytes32 pubKeyY,
        uint8 claimFlags,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 autoStakeDays,
        address referrerAddr
    ) external returns (uint256);

    function btcAddressClaims(bytes20) external view returns (bool);

    function btcAddressIsClaimable(
        bytes20 btcAddr,
        uint256 rawSatoshis,
        bytes32[] memory proof
    ) external view returns (bool);

    function btcAddressIsValid(
        bytes20 btcAddr,
        uint256 rawSatoshis,
        bytes32[] memory proof
    ) external pure returns (bool);

    function claimMessageMatchesSignature(
        address claimToAddr,
        bytes32 claimParamHash,
        bytes32 pubKeyX,
        bytes32 pubKeyY,
        uint8 claimFlags,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external pure returns (bool);

    function currentDay() external view returns (uint256);

    function dailyData(uint256)
        external
        view
        returns (
            uint72 dayPayoutTotal,
            uint72 dayStakeSharesTotal,
            uint56 dayUnclaimedSatoshisTotal
        );

    function dailyDataRange(uint256 beginDay, uint256 endDay)
        external
        view
        returns (uint256[] memory list);

    function dailyDataUpdate(uint256 beforeDay) external;

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function globalInfo() external view returns (uint256[13] memory);

    function globals()
        external
        view
        returns (
            uint72 lockedHeartsTotal,
            uint72 nextStakeSharesTotal,
            uint40 shareRate,
            uint72 stakePenaltyTotal,
            uint16 dailyDataCount,
            uint72 stakeSharesTotal,
            uint40 latestStakeId,
            uint128 claimStats
        );

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function merkleProofIsValid(bytes32 merkleLeaf, bytes32[] memory proof)
        external
        pure
        returns (bool);

    function name() external view returns (string memory);

    function pubKeyToBtcAddress(
        bytes32 pubKeyX,
        bytes32 pubKeyY,
        uint8 claimFlags
    ) external pure returns (bytes20);

    function pubKeyToEthAddress(bytes32 pubKeyX, bytes32 pubKeyY)
        external
        pure
        returns (address);

    function stakeCount(address stakerAddr) external view returns (uint256);

    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) external;

    function stakeGoodAccounting(
        address stakerAddr,
        uint256 stakeIndex,
        uint40 stakeIdParam
    ) external;

    function stakeLists(address, uint256)
        external
        view
        returns (
            uint40 stakeId,
            uint72 stakedHearts,
            uint72 stakeShares,
            uint16 lockedDay,
            uint16 stakedDays,
            uint16 unlockedDay,
            bool isAutoStake
        );

    function stakeStart(uint256 newStakedHearts, uint256 newStakedDays)
        external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function xfLobby(uint256) external view returns (uint256);

    function xfLobbyEnter(address referrerAddr) external payable;

    function xfLobbyEntry(address memberAddr, uint256 entryId)
        external
        view
        returns (uint256 rawAmount, address referrerAddr);

    function xfLobbyExit(uint256 enterDay, uint256 count) external;

    function xfLobbyFlush() external;

    function xfLobbyMembers(uint256, address)
        external
        view
        returns (uint40 headIndex, uint40 tailIndex);

    function xfLobbyPendingDays(address memberAddr)
        external
        view
        returns (uint256[2] memory words);

    function xfLobbyRange(uint256 beginDay, uint256 endDay)
        external
        view
        returns (uint256[] memory list);
}

struct HEXDailyData {
    uint72 dayPayoutTotal;
    uint72 dayStakeSharesTotal;
    uint56 dayUnclaimedSatoshisTotal;
}

struct HEXGlobals {
    uint72 lockedHeartsTotal;
    uint72 nextStakeSharesTotal;
    uint40 shareRate;
    uint72 stakePenaltyTotal;
    uint16 dailyDataCount;
    uint72 stakeSharesTotal;
    uint40 latestStakeId;
    uint128 claimStats;
}

struct HEXStake {
    uint40 stakeId;
    uint72 stakedHearts;
    uint72 stakeShares;
    uint16 lockedDay;
    uint16 stakedDays;
    uint16 unlockedDay;
    bool   isAutoStake;
}

struct HEXStakeMinimal {
    uint40 stakeId;
    uint72 stakeShares;
    uint16 lockedDay;
    uint16 stakedDays;
}

struct ShareStore {
    HEXStakeMinimal stake;
    uint16          mintedDays;
    uint8           launchBonus;
    uint16          loanStart;
    uint16          loanedDays;
    uint32          interestRate;
    uint8           paymentsMade;
    bool            isLoaned;
}

struct ShareCache {
    HEXStakeMinimal _stake;
    uint256         _mintedDays;
    uint256         _launchBonus;
    uint256         _loanStart;
    uint256         _loanedDays;
    uint256         _interestRate;
    uint256         _paymentsMade;
    bool            _isLoaned;
}

address constant _hdrnSourceAddress = address(0x9d73Ced2e36C89E5d167151809eeE218a189f801);
address constant _hdrnFlowAddress   = address(0xF447BE386164dADfB5d1e7622613f289F17024D8);
uint256 constant _hdrnLaunch        = 1645833600;

contract HEXStakeInstance {
    
    IHEX       private _hx;
    address    private _creator;
    ShareStore public  share;

    /**
     * @dev Updates the HSI's internal HEX stake data.
     */
    function _stakeDataUpdate(
    )
        internal
    {
        uint40 stakeId;
        uint72 stakedHearts;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
        bool   isAutoStake;
        
        (stakeId,
         stakedHearts,
         stakeShares,
         lockedDay,
         stakedDays,
         unlockedDay,
         isAutoStake
        ) = _hx.stakeLists(address(this), 0);

        share.stake.stakeId = stakeId;
        share.stake.stakeShares = stakeShares;
        share.stake.lockedDay = lockedDay;
        share.stake.stakedDays = stakedDays;
    }

    function initialize(
        address hexAddress
    ) 
        external 
    {
        require(_creator == address(0),
            "HSI: Initialization already performed");

        /* _creator is not an admin key. It is set at contsruction to be a link
           to the parent contract. In this case HSIM */
        _creator = msg.sender;

        // set HEX contract address
        _hx = IHEX(payable(hexAddress));
    }

    /**
     * @dev Creates a new HEX stake using all HEX ERC20 tokens assigned
     *      to the HSI's contract address. This is a privileged operation only
     *      HEXStakeInstanceManager.sol can call.
     * @param stakeLength Number of days the HEX ERC20 tokens will be staked.
     */
    function create(
        uint256 stakeLength
    )
        external
    {
        uint256 hexBalance = _hx.balanceOf(address(this));

        require(msg.sender == _creator,
            "HSI: Caller must be contract creator");
        require(share.stake.stakedDays == 0,
            "HSI: Creation already performed");
        require(hexBalance > 0,
            "HSI: Creation requires a non-zero HEX balance");

        _hx.stakeStart(
            hexBalance,
            stakeLength
        );

        _stakeDataUpdate();
    }

    /**
     * @dev Calls the HEX function "stakeGoodAccounting" against the
     *      HEX stake held within the HSI.
     */
    function goodAccounting(
    )
        external
    {
        require(share.stake.stakedDays > 0,
            "HSI: Creation not yet performed");

        _hx.stakeGoodAccounting(address(this), 0, share.stake.stakeId);

        _stakeDataUpdate();
    }

    /**
     * @dev Ends the HEX stake, approves the "_creator" address to transfer
     *      all HEX ERC20 tokens, and self-destructs the HSI. This is a 
     *      privileged operation only HEXStakeInstanceManager.sol can call.
     */
    function destroy(
    )
        external
    {
        require(msg.sender == _creator,
            "HSI: Caller must be contract creator");
        require(share.stake.stakedDays > 0,
            "HSI: Creation not yet performed");

        _hx.stakeEnd(0, share.stake.stakeId);
        
        uint256 hexBalance = _hx.balanceOf(address(this));

        if (_hx.approve(_creator, hexBalance)) {
            selfdestruct(payable(_creator));
        }
        else {
            revert();
        }
    }

    /**
     * @dev Updates the HSI's internal share data. This is a privileged 
     *      operation only HEXStakeInstanceManager.sol can call.
     * @param _share "ShareCache" object containing updated share data.
     */
    function update(
        ShareCache memory _share
    )
        external 
    {
        require(msg.sender == _creator,
            "HSI: Caller must be contract creator");

        share.mintedDays   = uint16(_share._mintedDays);
        share.launchBonus  = uint8 (_share._launchBonus);
        share.loanStart    = uint16(_share._loanStart);
        share.loanedDays   = uint16(_share._loanedDays);
        share.interestRate = uint32(_share._interestRate);
        share.paymentsMade = uint8 (_share._paymentsMade);
        share.isLoaned     = _share._isLoaned;
    }

    /**
     * @dev Fetches stake data from the HEX contract.
     * @return A "HEXStake" object containg the HEX stake data. 
     */
    function stakeDataFetch(
    ) 
        external
        view
        returns(HEXStake memory)
    {
        uint40 stakeId;
        uint72 stakedHearts;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
        bool   isAutoStake;
        
        (stakeId,
         stakedHearts,
         stakeShares,
         lockedDay,
         stakedDays,
         unlockedDay,
         isAutoStake
        ) = _hx.stakeLists(address(this), 0);

        return HEXStake(
            stakeId,
            stakedHearts,
            stakeShares,
            lockedDay,
            stakedDays,
            unlockedDay,
            isAutoStake
        );
    }
}