// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;
import "./Owned.sol";
contract Rate_Oracle is Owned {
    address public _operator_manager;
    address public _multisig;
    uint256 public _last_updated_rate;
    uint256 public _deviation;
    string public _pair;
    uint8 public _decimals;
    uint256 public _update_rate_price;
    mapping(address => uint) public _signerSignedBalances;
    mapping(address => uint) public _signerNotSignedBalances;

    constructor(string memory pair, address multisig, uint8 decimals, address operator_manager, uint256 deviation) {
        _multisig = multisig;
        _pair = pair;
        _decimals = decimals;
        _operator_manager = operator_manager;
        _deviation = deviation;
    }

    event RateUpdate(uint256 rate);
    function update_rate(uint256 rate) public Only_Operator_Manager {
        _last_updated_rate = rate;
    }

    function update_rate(uint256 rate, address[] calldata lastRoundSigned, address[] calldata lastRoundNotSigned) public Only_Multisig {
        //TODO protect this function from failling when price is below 100 (?)
        uint256 deviationFactor = (_last_updated_rate * _deviation) / 100;
        uint256 maxRate = _last_updated_rate + deviationFactor;
        uint256 minRate = _last_updated_rate - deviationFactor;
        require(rate <= maxRate && rate >= minRate, "New rate is outside the deviation range");
        _last_updated_rate = rate;

        for (uint i=0; i < lastRoundSigned.length; i++) {
            _signerSignedBalances[lastRoundSigned[i]]++;
        }

        for (uint i=0; i < lastRoundNotSigned.length; i++) {
            _signerNotSignedBalances[lastRoundNotSigned[i]]++;
        }

        emit RateUpdate(rate);
    }

    function claim(address signer) public Only_Operator_Manager{
        _signerSignedBalances[signer] = 0;
    }

    function slash(address signer) public Only_Operator_Manager{
        _signerNotSignedBalances[signer] = 0;
    }

    function update_pair(string memory pair) public onlyOwner{
        _pair = pair;
    }

    function update_multisig(address multisig) public onlyOwner{
        _multisig = multisig;
    }

    function update_operator_manager(address operator_manager) public onlyOwner{
        _operator_manager = operator_manager;
    }

    modifier Only_Multisig {
        require(msg.sender == _multisig, "Operator only");
        _;
    }

    modifier Only_Operator_Manager {
        require(msg.sender == _operator_manager, "Operator Manager only");
        _;
    }
    function get_rate() public payable returns (uint256) {
        require(msg.value >= _update_rate_price, "Insufficient payment");
        if (msg.value > _update_rate_price) {
            payable(msg.sender).transfer(msg.value - _update_rate_price);
        }
        return _last_updated_rate;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

/**
 * @title The Owned contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract Owned {

 address public owner;
 address private pendingOwner;

 event OwnershipTransferRequested(
 address indexed from,
 address indexed to
 );
 event OwnershipTransferred(
 address indexed from,
 address indexed to
 );

 constructor() {
 owner = msg.sender;
 }

 /**
 * @dev Allows an owner to begin transferring ownership to a new address,
 * pending.
 */
 function transferOwnership(address _to)
 external
 onlyOwner()
 {
 pendingOwner = _to;

 emit OwnershipTransferRequested(owner, _to);
 }

 /**
 * @dev Allows an ownership transfer to be completed by the recipient.
 */
 function acceptOwnership()
 external
 {
 require(msg.sender == pendingOwner, "Must be proposed owner");

 address oldOwner = owner;
 owner = msg.sender;
 pendingOwner = address(0);

 emit OwnershipTransferred(oldOwner, msg.sender);
 }

 /**
 * @dev Reverts if called by anyone other than the contract owner.
 */
 modifier onlyOwner() {
 require(msg.sender == owner, "Only callable by owner");
 _;
 }

}