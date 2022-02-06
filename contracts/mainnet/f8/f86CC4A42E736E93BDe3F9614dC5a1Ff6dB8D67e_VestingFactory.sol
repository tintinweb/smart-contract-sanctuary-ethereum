// SPDX-License-Identifier: MIT

//Token Locking Contract
pragma solidity ^0.8.10;

/**
 * token contract functions
*/
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./Initializable.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

interface ITokenVesting {
    function initialize (address token, address [] calldata beneficiary, uint256[] calldata duration, uint256[] calldata amount, uint256 timestamp) external;
}

contract TokenVesting is Ownable, ITokenVesting  {
    // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
    // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
    // it is recommended to avoid using short time durations (less than a minute). Typical vesting schemes, with a
    // cliff period of a year and a duration of four years, are safe to use.
    // solhint-disable not-rely-on-time

    address public factory;

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event TokensReleased(address token, uint256 amount);

    // beneficiary of tokens after they are released
    address[] private _beneficiary;

    // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
    uint256 private _start;
    uint256[] private _duration;
    uint256 private uniq;

    uint256[] private _amount;

    address private _token;


    mapping (uint256 => uint256) private _released;

    constructor () {
        factory = msg.sender;
    }

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param duration duration in seconds of the period in which the tokens will vest
     */
    function initialize (address token, address [] calldata beneficiary, uint256[] calldata duration, uint256[] calldata amount, uint256 timestamp) external override{
        
        uint256 len = beneficiary.length;
        uint256 len1 = duration.length;
        uint256 len2 = amount.length;
        require (len == len1 && len1 == len2, "All Arrays Should have the same length");
        for (uint256 i = 0; i < len; i++) {
            initializeSingle (beneficiary[i], duration[i], amount[i]);
        }
        _beneficiary = beneficiary;
        _amount = amount;
        _duration = duration;

        _start = block.timestamp;
        uniq = timestamp;
        _token = token;
    }

    function getToken () public view returns (address) {
        return _token;
    }

    function initializeSingle (address beneficiary, uint256 duration, uint256 amount) private pure {
        require(beneficiary != address(0), "TokenVesting: beneficiary is the zero address");
        // solhint-disable-next-line max-line-length
        require(duration > 0, "TokenVesting: duration is 0");
        require (amount > 0, "TokenVesting: amount is 0");
    }

    function getBeneficiaryIndex (address account) public view returns (int ind) {
        for (uint256 i = 0; i < _beneficiary.length; i++) {
            if (_beneficiary[i] == account) {
                return int (i);
            }
        }
        return -1;
    }

    function getDuration (uint256 ind) public view returns (uint256 duration) {
        return _duration[ind];
    }

    function getAmount (uint256 ind) public view returns (uint256 amount) {
        return _amount[ind];
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function getAllBeneficiaries () public view returns (address[] memory) {
        return _beneficiary;
    }

    /**
     * @return the start time of the token vesting.
     */
    function getStart() public view returns (uint256) {
        return _start;
    }

    /**
     * @return the amount of the token released.
     */
    function getReleased(uint256 ind) public view returns (uint256) {
        return _released[ind];
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release(uint256 ind) public {
        uint256 unreleased = _releasableAmount(ind);

        require(unreleased > 0, "TokenVesting: no tokens are due");

        _released[ind] = _released[ind].add(unreleased);

        IERC20 (_token).safeTransfer(_beneficiary[ind], unreleased);

        emit TokensReleased(address(_token), unreleased);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     */
    function _releasableAmount(uint256 ind) public view returns (uint256) {
        return _vestedAmount(ind).sub(_released[ind]);
    }

    /**
     * @dev Calculates the amount that has already vested.
     */
    function _vestedAmount(uint256 ind) private view returns (uint256) {

        if (block.timestamp >= _start.add(_duration[ind])) {
            return _amount[ind];
        } else {
            uint256 timePassed = block.timestamp - _start;
            uint256 timePassedHours = timePassed / 3600;
            uint256 allTimeHours = _duration[ind] / 3600;

            return _amount[ind].mul(timePassedHours).div(allTimeHours);
        }
    }

    function vestedAmount (uint256 ind) public view returns (uint256) {
        if (block.timestamp >= _start.add(_duration[ind])) {
            return _amount[ind];
        } else {
            uint256 timePassed = block.timestamp - _start;
            uint256 timePassedHours = timePassed / 3600;
            uint256 allTimeHours = _duration[ind] / 3600;

            return _amount[ind].mul(timePassedHours).div(allTimeHours);
        }
    }
}

interface IVestingFactory {
    event VestingCreated();

    function getVestingAddress(address) external view returns (address[] memory);
    function allVestingAddress(uint) external view returns (address vestingAddress);
    function allVestingAddressLength() external view returns (uint);
    function getVestingAddressByOwner (address) external view returns (address vestingAddress);

    function createVesting(address token, address [] calldata beneficiary, uint256[] calldata duration, uint256[] calldata amount) external returns (address vesting);
}

contract VestingFactory is IVestingFactory {
    bytes32 public constant INIT_CODE_POINT_HASH = keccak256(abi.encodePacked(type(TokenVesting).creationCode));

    mapping(address => address[]) public vestingAddresses;
    mapping(address => address) override public getVestingAddressByOwner;
    address[] override public allVestingAddress;

     function allVestingAddressLength() override public view returns (uint) {
        return allVestingAddress.length;
    }  
    
    function getVestingAddress (address beneficiary) override external view returns (address[] memory) {
        return vestingAddresses[beneficiary];
    }

    function createVesting(address token, address [] calldata beneficiary, uint256[] calldata duration, uint256[] calldata amount) override public returns (address vesting) {
        uint256 am = 0;
        for (uint i = 0; i < amount.length; i++) {
            am += amount[i];
        }
        require(ERC20(token).balanceOf(msg.sender) >= am, "createVesting: Cannot vest more than you hold.");

        bytes memory bytecode = type(TokenVesting).creationCode;
        uint256 timestamp = block.timestamp;
        bytes32 salt = keccak256(abi.encodePacked(token, beneficiary, duration, amount, timestamp));
        assembly {
            vesting := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ITokenVesting(vesting).initialize(token, beneficiary, duration, amount, timestamp);

        for (uint i = 0; i < beneficiary.length; i++) {
            vestingAddresses[beneficiary[i]].push (address (vesting));
        }

        require(ERC20(token).transferFrom(msg.sender, vesting, am), "createVesting: Transfer error");
        
        allVestingAddress.push(address (vesting));
        getVestingAddressByOwner[msg.sender] = address (vesting);

        emit VestingCreated();
    }
}