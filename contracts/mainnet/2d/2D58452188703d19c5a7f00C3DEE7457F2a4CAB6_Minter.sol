// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import {Auth, Authority} from "@rari-capital/solmate/src/auth/Auth.sol";
library Math {
    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface ve {
    function token() external view returns (address);
    function isUnlocked() external view returns (bool);
    function totalSupply() external view returns (uint);
    function create_lock_for(uint, uint, address) external returns (uint);
    function transferFrom(address, address, uint) external;
}

interface underlying {
    function approve(address spender, uint value) external returns (bool);
    function mint(address, uint) external;
    function setMinter(address) external;
    function totalSupply() external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function transfer(address, uint) external returns (bool);
}

interface voter {
    function notifyRewardAmount(uint amount) external;
}

interface ve_dist {
    function checkpoint_token() external;
    function setDepositor(address) external;
    function checkpoint_total_supply() external;
}

// codifies the minting rules as per ve(3,3), abstracted from the token to support any token that allows minting

//add safetransferlib
contract Minter is Auth {

    uint internal constant week = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
    uint internal emission = 98;
    uint internal tail_emission = 2;
    uint internal constant target_base = 100; // 2% per week target emission
    uint internal constant tail_base = 1000; // 0.2% per week target emission
    underlying public immutable _token;
    voter public _voter;
    ve public _ve;
    ve_dist public _ve_dist;
    uint public weekly = 625_000e18;
    uint public active_period;
    uint internal constant lock = 86400 * 7 * 52 * 2; //2 year lock

    address internal initializer;
    address internal airdrop;

    event Mint(address indexed sender, uint weekly, uint circulating_supply, uint circulating_emission);

    constructor(
        address GOVERNANCE_,
        address AUTHORITY_,
        address __voter, // the voting & distribution system
        address  __ve, // the veAPHRA system that will be locked into
        address __ve_dist // the distribution system that ensures users aren't diluted after unlock
    ) Auth(GOVERNANCE_, Authority(AUTHORITY_)) {
        initializer = msg.sender;
        _token = underlying(ve(__ve).token());
        _voter = voter(__voter);
        _ve = ve(__ve);
        _ve_dist = ve_dist(__ve_dist);
        active_period = (block.timestamp + (1 * week)) / week * week;

    }

    function initialize(
        address[] memory initVeLocks,
        uint[] memory initVeAmounts,
        address[] memory initToken,
        uint[] memory initTokenAmounts,
        uint max // sum amounts / max = % ownership of top protocols, so if initial 20m is distributed, and target is 25% protocol ownership, then max - 4 x 20m = 80m
    ) external {
        //setup initial mint params here, lock team as ve nft's
        //setup fund team vesting locks
        require(initializer == msg.sender);
        _token.mint(address(this), max);
        _token.approve(address(_ve), type(uint).max);

        for (uint i = 0; i < initVeLocks.length; i++) {
            _ve.create_lock_for(initVeAmounts[i], lock, initVeLocks[i]);
        }

        for (uint i = 0; i < initToken.length; i++) {
            _token.transfer(initToken[i], initTokenAmounts[i]);
        }

        //set to the last item in the initToken array as it is the airdrop and we want to exclude the airdrops balance
        // for supply emission calculations as it can only enter into ve when claimed
        airdrop = address(initToken[initToken.length - 1]);
        initializer = address(0);
        active_period = (block.timestamp + (1 * week)) / week * week;
    }

    function setEmission(uint newEmission_) external requiresAuth {
        emission = newEmission_;
    }

    function setTailEmission(uint newTailEmission_) external requiresAuth {
        tail_emission = newTailEmission_;
    }

    function setWeeklyRate(uint newWeeklyRate_) external requiresAuth {
        weekly = newWeeklyRate_;
    }

    function setVoter(address newVoter_) external requiresAuth {
        _voter = voter(newVoter_);
    }

    //for guarded launch
    function migrateMinter(address newMinter_) external requiresAuth {
        _token.setMinter(newMinter_);
    }

    //for guarded launch
    function changeVeDepositor(address newMinter_) external requiresAuth {
        _ve_dist.setDepositor(newMinter_);
    }

    // calculate circulating supply as total token supply - locked supply
    function circulating_supply() public view returns (uint) {
        return _token.totalSupply() - _ve.totalSupply() - _token.balanceOf(airdrop) - _token.balanceOf(owner);
    }

    // emission calculation is 2% of available supply to mint adjusted by circulating / total supply
    function calculate_emission() public view returns (uint) {
        return weekly * emission * circulating_supply() / target_base / _token.totalSupply();
    }

    // weekly emission takes the max of calculated (aka target) emission versus circulating tail end emission
    function weekly_emission() public view returns (uint) {
        if(!ve(_ve).isUnlocked()) {
            return weekly;
        }
        return Math.max(calculate_emission(), circulating_emission());
    }

    // calculates tail end (infinity) emissions as 0.2% of total supply
    function circulating_emission() public view returns (uint) {
        return circulating_supply() * tail_emission / tail_base;
    }

    // calculate inflation and adjust ve balances accordingly
    function calculate_growth(uint _minted) public view returns (uint) {
        if(!ve(_ve).isUnlocked()) {
            return 0;
        }
        return _ve.totalSupply() * _minted / _token.totalSupply();
    }

    // update period can only be called once per cycle (1 week)
    function update_period() external returns (uint) {
        uint _period = active_period;
        if (block.timestamp >= _period + week && initializer == address(0)) { // only trigger if new week
            _period = block.timestamp / week * week;
            active_period = _period;
            weekly = weekly_emission();

            uint _growth = calculate_growth(weekly);
            uint _required = _growth + weekly;
            uint _balanceOf = _token.balanceOf(address(this));
            if (_balanceOf < _required) {
                _token.mint(address(this), _required-_balanceOf);
            }

            require(_token.transfer(address(_ve_dist), _growth));
            _ve_dist.checkpoint_token(); // checkpoint token balance that was just minted in ve_dist
            _ve_dist.checkpoint_total_supply(); // checkpoint supply

            _token.approve(address(_voter), weekly);
            _voter.notifyRewardAmount(weekly);

            emit Mint(msg.sender, weekly, circulating_supply(), circulating_emission());
        }
        return _period;
    }

}