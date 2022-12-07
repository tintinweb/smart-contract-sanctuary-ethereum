// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

import "./ProxyPattern/SolidlyImplementation.sol";

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? b : a;
    }
}

interface veV2 {
    function token() external view returns (address);

    function totalSupply() external view returns (uint256);

    function create_lock_for(
        uint256,
        uint256,
        address
    ) external returns (uint256);

    function transferFrom(
        address,
        address,
        uint256
    ) external;
}

interface underlyingV2 {
    function approve(address spender, uint256 value) external returns (bool);

    function mint(address, uint256) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);
}

interface voterV2 {
    function notifyRewardAmount(uint256 amount) external;
}

interface ve_distV2 {
    function checkpoint_token() external;

    function checkpoint_total_supply() external;
}

// codifies the minting rules as per ve(3,3), abstracted from the token to support any token that allows minting
/**
 * @dev Changelog:
 *      - Deprecate constructor with initialize()
 *      - Deprecate initializer role with onlyGovernance and initialMinted
 *      - rename original initialize() -> initialMint()
 *      - Immutable storage slots became mutable but made sure nothing changes them after initialize()
 *      - New emissions curve to not go over 100m totalSupply()
 */
contract BaseV2Minter is SolidlyImplementation {
    uint256 public constant week = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
    uint256 internal constant emission = 98;
    uint256 internal constant tail_emission = 2;
    uint256 internal constant target_base = 100; // 2% per week target emission
    uint256 internal constant tail_base = 1000; // 0.2% per week target emission

    uint256 internal constant lock = 86400 * 7 * 52 * 4;

    /**
     * @dev storage slots start here
     */
    bool internal initialMinted;
    underlyingV2 public _token;
    voterV2 public _voter;
    veV2 public _ve;
    ve_distV2 public _ve_dist;
    uint256 public weekly = 20000000e18;
    uint256 public active_period;
    uint256 public targetSupply;

    uint256 public a;
    uint256 public b;
    uint256 public bDecayRate;
    mapping(uint256 => uint256) public humpFactor; // period -> humpFactor

    event Mint(
        address indexed sender,
        uint256 weekly,
        uint256 circulating_supply,
        uint256 circulating_emission
    );

    /**
     * @notice replaces constructor to set up contract states
     * @dev requires initializeProxy to be run before hand for onlyGovernance to work
     */
    function initialize(
        address __voter, // the voting & distribution system
        address __ve, // the ve(3,3) system that will be locked into
        address __ve_dist // the distribution system that ensures users aren't diluted
    ) external onlyGovernance notInitialized {
        _token = underlyingV2(veV2(__ve).token());
        _voter = voterV2(__voter);
        _ve = veV2(__ve);
        _ve_dist = ve_distV2(__ve_dist);
        // active_period = ((block.timestamp + (2 * week)) / week) * week;
        active_period = ((block.timestamp + (0 * week)) / week) * week;
        targetSupply = 100000000 ether;

        b = (((1 * 1e18) / 100000) * 100) / uint256(99);
        a = (3 * 1e18) / 1000 - b;
        bDecayRate = (99 * 1e18) / 100;
    }

    function initialMint(
        address[] memory claimants,
        uint256[] memory amounts,
        uint256 max // sum amounts / max = % ownership of top protocols, so if initial 20m is distributed, and target is 25% protocol ownership, then max - 4 x 20m = 80m
    ) external onlyGovernance {
        require(!initialMinted, "Already minted"); // can only initialMint once;
        initialMinted = true;
        _token.mint(address(this), max);
        _token.approve(address(_ve), type(uint256).max);
        for (uint256 i = 0; i < claimants.length; i++) {
            _ve.create_lock_for(amounts[i], lock, claimants[i]);
        }
        _token.transfer(governanceAddress(), _token.balanceOf(address(this)));
        // active_period = ((block.timestamp + week) / week) * week;
        active_period = ((block.timestamp + 0 * week) / week) * week;
    }

    /**
     * @notice Sets parameters for the emissions curve
     * @param _a The component that is constant in the curve
     * @param _b The component that will be decaying with time
     * @param _bDecayRate The rate at which b decays
     */
    function setEmissionsCurve(
        uint256 _a,
        uint256 _b,
        uint256 _bDecayRate
    ) external onlyGovernance {
        a = _a;
        b = _b;
        bDecayRate = _bDecayRate;
    }

    /**
     * @notice Sets humpFactors, used to temporarily boost emissions
     */
    function setHumpFactors(
        uint256[] calldata _periods,
        uint256[] calldata _humpFactors
    ) external onlyGovernance {
        require(_periods.length == _humpFactors.length, "Length mismatch");
        for (uint256 i = 0; i < _periods.length; i++) {
            humpFactor[_periods[i]] = _humpFactors[i];
        }
    }

    // calculate circulating supply as total token supply - locked supply
    function circulating_supply() public view returns (uint256) {
        return
            _token.totalSupply() -
            _ve.totalSupply() -
            _token.balanceOf(address(this));
    }

    /**
     * @notice Weekly emission that is based on a maximum total supply of targetSupply
     */
    function calculate_emission() public view returns (uint256) {
        uint256 totalSupply = _token.totalSupply();
        if (totalSupply > targetSupply) return 0;

        uint256 _emission = ((((targetSupply - totalSupply) * (a + b)) / 1e18) *
            (humpFactor[active_period + week] + 10000)) / 10000;
        return _emission;
    }

    /**
     * @notice Weekly emission
     * @dev Returns calculate_emission(), kept for backwards compatibility
     */
    function weekly_emission() public view returns (uint256) {
        return calculate_emission();
    }

    /**
     * @notice Weekly emission
     * @dev Returns calculate_emission(), kept for backwards compatibility
     */
    function circulating_emission() public view returns (uint256) {
        return calculate_emission();
    }

    // calculate inflation and adjust ve balances accordingly
    function calculate_growth(uint256 _minted) public view returns (uint256) {
        return
            (_ve.totalSupply() * _minted) /
            (_token.totalSupply() - _token.balanceOf(address(this)));
    }

    // update period can only be called once per cycle (1 week)
    function update_period() external returns (uint256) {
        uint256 _period = active_period;
        if (block.timestamp >= _period + week && initialMinted) {
            // only trigger if new week
            _period = (block.timestamp / week) * week;
            uint256 _weekly = weekly_emission();
            weekly = _weekly;
            uint256 _growth = Math.min(calculate_growth(_weekly), _weekly); // Sanity check, anti-dilution cannot be more than weekly

            active_period = _period;
            a = a + b;
            b = (b * bDecayRate) / 1e18; // decay b for next week's emissions

            uint256 _required = _growth + weekly;
            uint256 _balanceOf = _token.balanceOf(address(this));
            if (_balanceOf < _required) {
                _token.mint(address(this), _required - _balanceOf);
            }

            require(_token.transfer(address(_ve_dist), _growth));
            _ve_dist.checkpoint_token(); // checkpoint token balance that was just minted in ve_dist
            _ve_dist.checkpoint_total_supply(); // checkpoint supply

            _token.approve(address(_voter), weekly);
            _voter.notifyRewardAmount(weekly);

            emit Mint(
                msg.sender,
                weekly,
                circulating_supply(),
                circulating_emission()
            );
        }
        return _period;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

/**
 * @title Solidly+ Implementation
 * @author Solidly+
 * @notice Governable implementation that relies on governance slot to be set by the proxy
 */
contract SolidlyImplementation {
    bytes32 constant GOVERNANCE_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103; // keccak256('eip1967.proxy.admin')
    bytes32 constant INITIALIZED_SLOT =
        0x834ce84547018237034401a09067277cdcbe7bbf7d7d30f6b382b0a102b7b4a3; // keccak256('eip1967.proxy.initialized')

    /**
     * @notice Reverts if msg.sender is not governance
     */
    modifier onlyGovernance() {
        require(msg.sender == governanceAddress(), "Only governance");
        _;
    }

    /**
     * @notice Reverts if contract is already initialized
     * @dev U4sed by implementations to ensure initialize() is only called once
     */
    modifier notInitialized() {
        bool initialized;
        assembly {
            initialized := sload(INITIALIZED_SLOT)
            if eq(initialized, 1) {
                revert(0, 0)
            }
        }
        _;
    }

    /**
     * @notice Fetch current governance address
     * @return _governanceAddress Returns current governance address
     */
    function governanceAddress()
        public
        view
        virtual
        returns (address _governanceAddress)
    {
        assembly {
            _governanceAddress := sload(GOVERNANCE_SLOT)
        }
    }
}