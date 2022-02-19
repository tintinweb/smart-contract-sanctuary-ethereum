/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


contract Staking {
    using Address for address;
    using Address for address payable;

    // Parameters
    uint128 public constant ValidatorThreshold = 1 ether;
    uint32 public constant MinimumRequiredNumValidators = 4;

    // Properties
    address[] public _validators;
    mapping(address => bool) _addressToIsValidator;
    mapping(address => uint256) _addressToStakedAmount;
    mapping(address => uint256) _addressToValidatorIndex;
    uint256 _stakedAmount;
	address _master;

    // Events
    event Staked(address indexed account, uint256 amount);

    event Unstaked(address indexed account, uint256 amount);

    // Modifiers
    modifier onlyEOA() {
        require(!msg.sender.isContract(), "Only EOA can call function");
        _;
    }

    modifier onlyStaker() {
        require(
            _addressToStakedAmount[msg.sender] > 0,
            "Only staker can call function"
        );
        _;
    }

    modifier onlyMaster() {
		require(msg.sender == _master, "only Master");
		_;
	}
	
    constructor() public {
		_master = msg.sender;
		_addValidator(0x5c10c37559EeC0A6372497aD546B1D103572Ab71);
		_addValidator(0x697E5b64543D7E8523415c27bde3FED24b27485F);
		_addValidator(0x03b10e452dC9eEf49DFA17D7f9A5269676f7Ef3d);
		_addValidator(0x09f8600161c309F6c9f8C409b1107D5CDC5D621A);
	}

    // View functions
    function master() external view returns (address) {
        return _master;
    }

    function stakedAmount() public view returns (uint256) {
        //return _stakedAmount;
        return ValidatorThreshold * _validators.length;
    }

    function validators() public view returns (address[] memory) {
        return _validators;
    }

    function isValidator(address addr) public view returns (bool) {
        return _addressToIsValidator[addr];
    }

    function accountStake(address addr) public view returns (uint256) {
        //return _addressToStakedAmount[addr];
        if(isValidator(addr))
            return ValidatorThreshold;
        else
            return 0;
    }

    // Public functions
    receive() external payable onlyEOA {
        //_stake();
    }

    function stake() public payable onlyEOA {
        //_stake();
    }

    function unstake() public onlyEOA onlyStaker {
        //_unstake();
    }

    // Private functions
    function _stake() private {
        _stakedAmount += msg.value;
        _addressToStakedAmount[msg.sender] += msg.value;

        if (
            !_addressToIsValidator[msg.sender] &&
            _addressToStakedAmount[msg.sender] >= ValidatorThreshold
        ) {
            // append to validator set
            //_addressToIsValidator[msg.sender] = true;
            //_addressToValidatorIndex[msg.sender] = _validators.length;
            //_validators.push(msg.sender);
			_addValidator(msg.sender);
        }

        emit Staked(msg.sender, msg.value);
    }

    function _unstake() private {
        require(
            _validators.length > MinimumRequiredNumValidators,
            "Number of validators can't be less than MinimumRequiredNumValidators"
        );

        uint256 amount = _addressToStakedAmount[msg.sender];

        if (_addressToIsValidator[msg.sender]) {
            _deleteFromValidators(msg.sender);
        }

        _addressToStakedAmount[msg.sender] = 0;
        _stakedAmount -= amount;
        payable(msg.sender).transfer(amount);
        emit Unstaked(msg.sender, amount);
    }

	function addValidator(address staker) external onlyMaster {
		_addValidator(staker);
	}
	function _addValidator(address staker) private {
		// append to validator set
		_addressToIsValidator[staker] = true;
		_addressToValidatorIndex[staker] = _validators.length;
		_validators.push(staker);
	}
	
	function deleteFromValidators(address staker) external onlyMaster {
		_deleteFromValidators(staker);
	}
	function _deleteFromValidators(address staker) private {
        require(
            _addressToValidatorIndex[staker] < _validators.length,
            "index out of range"
        );

        // index of removed address
        uint256 index = _addressToValidatorIndex[staker];
        uint256 lastIndex = _validators.length - 1;

        if (index != lastIndex) {
            // exchange between the element and last to pop for delete
            address lastAddr = _validators[lastIndex];
            _validators[index] = lastAddr;
            _addressToValidatorIndex[lastAddr] = index;
        }

        _addressToIsValidator[staker] = false;
        _addressToValidatorIndex[staker] = 0;
        _validators.pop();
    }
	
    function transferMaster(address newMaster) external onlyMaster {
        //require(newMaster != address(0));
        emit TransferMaster(_master, newMaster);
        _master = newMaster;
    }
    event TransferMaster(address indexed oldMaster, address indexed newMaster);
}