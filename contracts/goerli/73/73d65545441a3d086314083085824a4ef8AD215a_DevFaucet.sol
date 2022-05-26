// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "../interfaces/IERC20.sol";
import "../interfaces/IStaking.sol";
import "../types/Ownable.sol";
import "../types/OlympusAccessControlled.sol";

interface IFaucet is IERC20 {
    function faucetMint(address recipient_) external;
}

interface IStakingV1 {
    function stake(uint256 amount_, address recipient_) external returns (bool);

    function claim(address recipient_) external;
}

interface IWOHM is IERC20 {
    function wrapFromOHM(uint256 amount_) external returns (uint256);
}

/// TODO - get this to be forward compatible if new contracts are deployed
///        i.e. if a new token is added, how can we mint without redeploying a contract
///        Add daily limit to prevent abuse
contract DevFaucet is OlympusAccessControlled {
    /*================== ERRORS ==================*/

    error CanOnlyMintOnceADay();
    error MintTooLarge();

    /*============= STATE VARIABLES =============*/
    IERC20 public DAI;
    IFaucet[] public mintable;
    IWOHM public wsOHM;

    /// Define current staking contracts
    /// @dev These have to be specifically and separately defined because they do not have
    ///      compatible interfaces
    IStakingV1 public stakingV1;
    IStaking public stakingV2;

    /// Define array to push future staking contracts to if they are ever swapped
    /// @dev These have to conform to the current staking interface (or at least the stake function)
    IStaking[] public futureStaking;

    /// Keep track of the last block a user minted at so we can prevent spam
    mapping(address => uint256) public lastMint;

    constructor(
        address dai_,
        address ohmV1_,
        address ohmV2_,
        address wsOHM_,
        address stakingV1_,
        address stakingV2_,
        address authority_
    ) OlympusAccessControlled(IOlympusAuthority(authority_)) {
        DAI = IERC20(dai_);
        mintable.push(IFaucet(ohmV1_));
        mintable.push(IFaucet(ohmV2_));
        wsOHM = IWOHM(wsOHM_);
        stakingV1 = IStakingV1(stakingV1_);
        stakingV2 = IStaking(stakingV2_);

        mintable[0].approve(wsOHM_, type(uint256).max);
        mintable[0].approve(stakingV1_, type(uint256).max);
        mintable[1].approve(stakingV2_, type(uint256).max);
    }

    /*================== Modifiers ==================*/

    function _beenADay(uint256 lastMint_, uint256 timestamp_) internal pure returns (bool) {
        return (timestamp_ - lastMint_) > 1 days;
    }

    /*=============== FAUCET FUNCTIONS ===============*/

    function mintDAI() external {
        if (!_beenADay(lastMint[msg.sender], block.timestamp)) revert CanOnlyMintOnceADay();

        lastMint[msg.sender] = block.timestamp;

        DAI.transfer(msg.sender, 100000000000000000000);
    }

    function mintETH(uint256 amount_) external {
        if (!_beenADay(lastMint[msg.sender], block.timestamp)) revert CanOnlyMintOnceADay();
        if (amount_ > 150000000000000000) revert MintTooLarge();

        lastMint[msg.sender] = block.timestamp;

        /// Transfer rather than Send so it reverts if balance too low
        payable(msg.sender).transfer(amount_);
    }

    function mintOHM(uint256 ohmIndex_) external {
        if (!_beenADay(lastMint[msg.sender], block.timestamp)) revert CanOnlyMintOnceADay();

        lastMint[msg.sender] = block.timestamp;

        IFaucet ohm = mintable[ohmIndex_];

        if (ohm.balanceOf(address(this)) < 10000000000) {
            ohm.faucetMint(msg.sender);
        } else {
            ohm.transfer(msg.sender, 10000000000);
        }
    }

    function mintSOHM(uint256 ohmIndex_) external {
        if (!_beenADay(lastMint[msg.sender], block.timestamp)) revert CanOnlyMintOnceADay();

        lastMint[msg.sender] = block.timestamp;

        IFaucet ohm = mintable[ohmIndex_];

        if (ohm.balanceOf(address(this)) < 10000000000) {
            ohm.faucetMint(address(this));
        }

        if (ohmIndex_ > 1) {
            IStaking currStaking = futureStaking[ohmIndex_ - 2];
            currStaking.stake(msg.sender, 10000000000, true, true);
        } else if (ohmIndex_ == 1) {
            stakingV2.stake(msg.sender, 10000000000, true, true);
        } else {
            stakingV1.stake(10000000000, msg.sender);
            stakingV1.claim(msg.sender);
        }
    }

    function mintWSOHM() external {
        if (!_beenADay(lastMint[msg.sender], block.timestamp)) revert CanOnlyMintOnceADay();

        lastMint[msg.sender] = block.timestamp;

        if (mintable[0].balanceOf(address(this)) < 10000000000) {
            mintable[0].faucetMint(address(this));
        }

        uint256 wsOHMMinted = wsOHM.wrapFromOHM(10000000000);
        wsOHM.transfer(msg.sender, wsOHMMinted);
    }

    function mintGOHM() external {
        if (!_beenADay(lastMint[msg.sender], block.timestamp)) revert CanOnlyMintOnceADay();

        lastMint[msg.sender] = block.timestamp;

        if (mintable[1].balanceOf(address(this)) < 10000000000) {
            mintable[1].faucetMint(address(this));
        }

        stakingV2.stake(msg.sender, 10000000000, false, true);
    }

    /*=============== CONFIG FUNCTIONS ===============*/

    function setDAI(address dai_) external onlyGovernor {
        DAI = IERC20(dai_);
    }

    function setOHM(uint256 ohmIndex_, address ohm_) external onlyGovernor {
        mintable[ohmIndex_] = IFaucet(ohm_);
    }

    function addOHM(address ohm_) external onlyGovernor {
        mintable.push(IFaucet(ohm_));
    }

    function setStakingV1(address stakingV1_) external onlyGovernor {
        stakingV1 = IStakingV1(stakingV1_);
    }

    function setStakingV2(address stakingV2_) external onlyGovernor {
        stakingV2 = IStaking(stakingV2_);
    }

    function addStaking(address staking_) external onlyGovernor {
        futureStaking.push(IStaking(staking_));
    }

    function approveStaking(address ohm_, address staking_) external onlyGovernor {
        IERC20(ohm_).approve(staking_, type(uint256).max);
    }

    /*=============== RECEIVE FUNCTION ===============*/

    receive() external payable {
        return;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IStaking {
    function stake(
        address _to,
        uint256 _amount,
        bool _rebasing,
        bool _claim
    ) external returns (uint256);

    function claim(address _recipient, bool _rebasing) external returns (uint256);

    function forfeit() external returns (uint256);

    function toggleLock() external;

    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256);

    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_);

    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_);

    function rebase() external;

    function index() external view returns (uint256);

    function contractBalance() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function supplyInWarmup() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

import "../interfaces/IOwnable.sol";

abstract contract Ownable is IOwnable {
    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceManagement() public virtual override onlyOwner {
        emit OwnershipPulled(_owner, address(0));
        _owner = address(0);
        _newOwner = address(0);
    }

    function pushManagement(address newOwner_) public virtual override onlyOwner {
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
        _newOwner = address(0);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../interfaces/IOlympusAuthority.sol";

abstract contract OlympusAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IOlympusAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IOlympusAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IOlympusAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(IOlympusAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IOwnable {
    function owner() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IOlympusAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}