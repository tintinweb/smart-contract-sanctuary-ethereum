// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Proxy {

    function calculateProxyAddress(uint256[] calldata a, bytes memory _salt, address cointoolAddress, address xenAddress) external view returns (XENCrypto.MintInfo[] memory) {
        bytes32 bytecode = keccak256(abi.encodePacked(bytes.concat(bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73), bytes20(cointoolAddress), bytes15(0x5af43d82803e903d91602b57fd5bf3))));
        uint256 i = 0;
        address[] memory proxy = new address[](a.length);
        XENCrypto.MintInfo[] memory userInfo = new XENCrypto.MintInfo[](a.length);

        for (i; i<a.length; i++) {
            bytes32 salt = keccak256(abi.encodePacked(_salt,a[i],msg.sender));
            proxy[i] = address(uint160(uint(keccak256(abi.encodePacked(
                    hex'ff',
                    cointoolAddress,
                    salt,
                    bytecode
                )))));
            userInfo[i] = (XENCrypto(xenAddress).userMints(proxy[i]));
        }
        
        return userInfo;
    }
    
}

interface XENCrypto {
    struct MintInfo {
        address user;
        uint256 term;
        uint256 maturityTs;
        uint256 rank;
        uint256 amplifier;
        uint256 eaaRate;
    }

    struct StakeInfo {
        uint256 term;
        uint256 maturityTs;
        uint256 amount;
        uint256 apy;
    }

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event MintClaimed(address indexed user, uint256 rewardAmount);
    event RankClaimed(address indexed user, uint256 term, uint256 rank);
    event Staked(address indexed user, uint256 amount, uint256 term);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Withdrawn(address indexed user, uint256 amount, uint256 reward);

    function AUTHORS() external view returns (string memory);

    function DAYS_IN_YEAR() external view returns (uint256);

    function EAA_PM_START() external view returns (uint256);

    function EAA_PM_STEP() external view returns (uint256);

    function EAA_RANK_STEP() external view returns (uint256);

    function GENESIS_RANK() external view returns (uint256);

    function MAX_PENALTY_PCT() external view returns (uint256);

    function MAX_TERM_END() external view returns (uint256);

    function MAX_TERM_START() external view returns (uint256);

    function MIN_TERM() external view returns (uint256);

    function REWARD_AMPLIFIER_END() external view returns (uint256);

    function REWARD_AMPLIFIER_START() external view returns (uint256);

    function SECONDS_IN_DAY() external view returns (uint256);

    function TERM_AMPLIFIER() external view returns (uint256);

    function TERM_AMPLIFIER_THRESHOLD() external view returns (uint256);

    function WITHDRAWAL_WINDOW_DAYS() external view returns (uint256);

    function XEN_APY_DAYS_STEP() external view returns (uint256);

    function XEN_APY_END() external view returns (uint256);

    function XEN_APY_START() external view returns (uint256);

    function XEN_MIN_BURN() external view returns (uint256);

    function XEN_MIN_STAKE() external view returns (uint256);

    function activeMinters() external view returns (uint256);

    function activeStakes() external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function burn(address user, uint256 amount) external;

    function claimMintReward() external;

    function claimMintRewardAndShare(address other, uint256 pct) external;

    function claimMintRewardAndStake(uint256 pct, uint256 term) external;

    function claimRank(uint256 term) external;

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function genesisTs() external view returns (uint256);

    function getCurrentAMP() external view returns (uint256);

    function getCurrentAPY() external view returns (uint256);

    function getCurrentEAAR() external view returns (uint256);

    function getCurrentMaxTerm() external view returns (uint256);

    function getGrossReward(
        uint256 rankDelta,
        uint256 amplifier,
        uint256 term,
        uint256 eaa
    ) external pure returns (uint256);

    function getUserMint() external view returns (MintInfo memory);

    function getUserStake() external view returns (StakeInfo memory);

    function globalRank() external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function name() external view returns (string memory);

    function stake(uint256 amount, uint256 term) external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function totalXenStaked() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function userBurns(address) external view returns (uint256);

    function userMints(address)
        external
        view
        returns (
            MintInfo memory
        );

    function userStakes(address)
        external
        view
        returns (
            StakeInfo memory
        );

    function withdraw() external;
}