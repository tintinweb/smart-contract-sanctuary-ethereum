/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

// File: interfaces/OracleWrapper.sol


pragma solidity ^0.8.4;

interface OracleWrapper {
    function latestAnswer() external view returns (uint128);
}

// File: interfaces/IERC20.sol


pragma solidity ^0.8.4;

interface Token {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// File: utils/Ownable.sol


pragma solidity ^0.8.4;

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function _setOwner(address newOwner) internal {
        owner = newOwner;
    }
}

// File: libraries/TransferHelper.sol


pragma solidity ^0.8.4;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// File: utils/ReentrancyGuard.sol


pragma solidity ^0.8.4;

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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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



// File: CHBTeam.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;






contract CHBTeam is Ownable {
    address public tokenAddress; // CHB Token address
    uint64 public decimalValue; // Token decimals
    uint32 public startTimestamp; // Time at which contract is deployed
    uint32 public firstClaimTimestamp; // Time at which first first claim will be available
    uint32 public lastClaimTimestamp; // Time at which claims will be over
    uint32 public timeIntervals; // Time interval between 2 claims
    uint8 public totalTeams; // Total teams available
    uint8 public currentTeamCount;

    // Team Addresses
    address public DEVELOPMENT = 0xab1322Fd34dA21F564F1ff7E83371A46E7dDac98;
    address public MARKETING = 0x8cD523AB00c13FB71b7Ad1692d6815b0b2eC37a9;
    address public SECURITY = 0xDCa990Cf44A7Ed377DCD262ECC9B2d25078BAc74;
    address public LEGAL = 0x1D29A0605300CBD35402d8c3105a11FEcf7cd29A;

    /* ================ STRUCT SECTION ================ */
    // Struct for teams
    struct Team {
        address teamAddress;
        uint128 totalTokens;
        uint128 tokensClaimed;
        uint128 tokenDistribution;
        uint32 claimCount;
        uint32 vestingPeriod;
        bool isActive;
    }
    mapping(address => Team) public teamInfo;
    mapping(address => uint128) public teamShare;

    /* ================ EVENT SECTION ================ */
    event TeamCreated(
        address indexed teamAddress,
        uint128 totalTokens,
        uint128 tokensClaimed,
        uint128 tokenDistribution,
        uint32 claimCount,
        uint32 vestingPeriod
    );

    event TokensClaimed(
        address indexed teamAddress,
        uint128 tokensClaimed,
        uint32 claimCount
    );

    /* ================ CONSTRUCTOR SECTION ================ */
    // Construtor
    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;

        decimalValue = uint64(10**Token(tokenAddress).decimals());

        startTimestamp = uint32(block.timestamp);
        firstClaimTimestamp = startTimestamp + 300 days;
        lastClaimTimestamp = startTimestamp + 1800 days;
        timeIntervals = 30 days;
        totalTeams = 4;

        teamShare[DEVELOPMENT] = 70_00_00_000 * decimalValue;
        teamShare[MARKETING] = 80_00_00_000 * decimalValue;
        teamShare[SECURITY] = 30_00_00_000 * decimalValue;
        teamShare[LEGAL] = 20_00_00_000 * decimalValue;

        registerTeam(DEVELOPMENT, teamShare[DEVELOPMENT]);
        registerTeam(MARKETING, teamShare[MARKETING]);
        registerTeam(SECURITY, teamShare[SECURITY]);
        registerTeam(LEGAL, teamShare[LEGAL]);
    }

    /* ================ TEAM FUNCTION SECTION ================ */

    // Function registers new team
    function registerTeam(address _teamAddress, uint128 _teamShare)
        public
        onlyOwner
    {
        // Only 4 teams are allowed
        require(currentTeamCount < totalTeams, "Maximum teams created");

        // Team should not be already registered
        require(!teamInfo[_teamAddress].isActive, "Team already registered");

        // New team instance created
        Team memory newTeam = Team({
            teamAddress: _teamAddress,
            totalTokens: _teamShare,
            tokensClaimed: 0,
            tokenDistribution: (_teamShare * 200) / 10000,
            claimCount: 0,
            vestingPeriod: lastClaimTimestamp,
            isActive: true
        });
        teamInfo[_teamAddress] = newTeam;
        ++currentTeamCount;

        emit TeamCreated(
            _teamAddress,
            newTeam.totalTokens,
            newTeam.tokensClaimed,
            newTeam.tokenDistribution,
            newTeam.claimCount,
            newTeam.vestingPeriod
        );
    }

    // Function allows teams to claim tokens
    function claimTokens() public {
        Team storage tInfo = teamInfo[msg.sender];

        require(tInfo.isActive, "Team doesn't exist");
        require(block.timestamp > firstClaimTimestamp, "Tokens in vesting");

        uint32 _totalClaims = teamTotalClaims(firstClaimTimestamp, 0);
        if (_totalClaims > tInfo.claimCount) {
            uint128 _totalTokensToClaim = (_totalClaims - tInfo.claimCount) *
                tInfo.tokenDistribution;

            TransferHelper.safeTransfer(
                tokenAddress,
                msg.sender,
                _totalTokensToClaim
            );

            tInfo.claimCount = _totalClaims;
            tInfo.tokensClaimed += _totalTokensToClaim;
        } else {
            if (block.timestamp < firstClaimTimestamp) {
                require(false, "Vesting time is still on");
            } else {
                require(false, "Maximum tokens available already claimed");
            }
        }

        emit TokensClaimed(msg.sender, tInfo.tokensClaimed, tInfo.claimCount);
    }

    // Internal function to return claims
    function teamTotalClaims(uint32 _timestamp, uint32 _totalClaims)
        public
        view
        returns (uint32)
    {
        if (block.timestamp >= _timestamp) {
            if (_totalClaims < 50) {
                ++_totalClaims;
                return
                    teamTotalClaims(_timestamp + timeIntervals, _totalClaims);
            } else {
                return _totalClaims;
            }
        } else {
            return _totalClaims;
        }
    }
}