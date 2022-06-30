//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Address.sol";
import "./Clones.sol";
import "./PaymentSplitterCloneable.sol";

/**
 * @title PaymentSplitterManagerClones
 * @dev This contract allows users to create and track minimal proxy contracts (clones) of an implementation of PaymentSplitter
 *
 */
contract PaymentSplitterManagerClones is Ownable {
    mapping(address => address[]) private _createdSplitters;
    mapping(address => address[]) private _registeredSplitters;
    address[] public splitters;

    uint public tax;
    
    event PaymentSplitterCreated(address newSplitter);

    /**
     * @dev Creates an instance of `PaymentSplitterManagerClones`.
     */
    constructor () {
        PaymentSplitterCloneable implementation = new PaymentSplitterCloneable();
        address[] memory payees_ = new address[](1);
        payees_[0] = address(this);
        uint256[] memory shares_ = new uint256[](1);
        shares_[0] = 1;
        implementation.initialize(payees_, shares_);
        splitters.push(address(implementation));
        _createdSplitters[address(this)].push(address(implementation));
        _registeredSplitters[address(this)].push(address(implementation));
    }

    /**
     * @dev Getter for the address of the PaymentSplitterCloneable implementation contract.
     */
    function splitterImplementation() public view returns (address) {
        return splitters[0];
    }

    /**
     * @dev Getter for the number of PaymentSplitters registered where `_target` has shares.
     */
    function registeredCountOf(address _target) external view returns (uint) {
        return _registeredSplitters[_target].length;
    }

    /**
     * @dev Getter for the addresses of the PaymentSplitters registered where `_target` has shares.
     */
    function registeredSplittersOf(address _target) external view returns (address[] memory) {
        return _registeredSplitters[_target];
    }

    /**
     * @dev Getter for the address of the PaymentSplitters created by `_target`.
     */
    function createdSplittersOf(address _target) external view returns (address[] memory) {
        return _createdSplitters[_target];
    }

    /**
     * @dev Set the price of clones.
     */
    function setTax(uint _tax) external onlyOwner {
        tax = _tax;
    }

    /**
     * @dev Spawn a new PaymentSplitter passing in `payees_` and `shares_` to its initializer, and 
     * records the splitter in memory.
     */
    function newSplitter(address[] memory payees_, uint256[] memory shares_) external payable {
        require(msg.value >= tax);
        address _newSplitter = Clones.clone(splitterImplementation());
        PaymentSplitterCloneable(payable(_newSplitter)).initialize(payees_, shares_);
        splitters.push(_newSplitter);
        _createdSplitters[msg.sender].push(_newSplitter);
        for(uint i = 0; i < payees_.length; i++) {
            _registeredSplitters[payees_[i]].push(_newSplitter);
        }
    }

    /**
     * @dev Release funds associated with the address `_recv`. `_ids` is an array of indexes into 
     * `_registeredSplitters`.
     */
    function shakeIndex(address payable _recv, uint [] memory _ids) external {
        for(uint i = 0; i < _ids.length; i++) {
            PaymentSplitterCloneable(payable(_registeredSplitters[_recv][_ids[i]])).release(_recv);
        }
    }

    /**
     * @dev Release funds associated with the address `_recv`. `_start` and `_end` are bounds on
     * indexes in `_registeredSplitters`.
     */
    function shakeRange(address payable _recv, uint _start, uint _end) external {
        for(uint i = _start; i < _end; i++) {
            PaymentSplitterCloneable(payable(_registeredSplitters[_recv][i])).release(_recv);
        }
    }

    /**
     * @dev Release all funds associated with the address `_recv`.
     */
    function shakeAll(address payable _recv) external {
        for(uint i = 0; i < _registeredSplitters[_recv].length; i++){
            PaymentSplitterCloneable(payable(_registeredSplitters[_recv][i])).release(_recv);
        }
    }

    /**
     * @dev Admin function to collect tax.
     */
    function release(address payable _recv, uint _amount) external onlyOwner {
        Address.sendValue(_recv, _amount);
    }

    // Views
    /**
     * @dev Getter helper for the amount of shares held by an account.
     */
    function sharesOfAccount(address splitter, address account) public view returns (uint256) {
        return PaymentSplitterCloneable(payable(splitter)).shares(account);
    }

    /**
     * @dev Getter helper for the shares distribution of the splitter at `splitter`.
     */
    function shares(address splitter) public view returns (uint256[] memory) {
        PaymentSplitterCloneable psc = PaymentSplitterCloneable(payable(splitter));

        uint numPayees = psc.numPayees();
        uint256[] memory shares_ = new uint256[](numPayees);
        for (uint i = 0; i < numPayees; i++) {
            address p = psc.payee(i); 
            shares_[i] = psc.shares(p);
        }
        return shares_;
    }

    /**
     * @dev Getter helper for the payee number `index` of the splitter `splitter`.
     */
    function payee(address splitter, uint256 index) public view returns (address) {
        return PaymentSplitterCloneable(payable(splitter)).payee(index);
    }

    /**
     * @dev Getter helper for the payees of the splitter at `splitter`.
     */
    function payees(address splitter) public view returns ( address[] memory) {
        PaymentSplitterCloneable psc = PaymentSplitterCloneable(payable(splitter));
        uint numPayees = psc.numPayees();
        address[] memory payees_ = new address[](numPayees);
        for (uint i = 0; i < numPayees; i++) {
            payees_[i] = psc.payee(i);
        }
        return payees_;
    }

    /**
     * @dev Getter helper for the current releaseable funds associated with each payee in the 
     * splitter at `splitter`.
     */
    function balances(address splitter) public view returns (uint256[] memory) {
        PaymentSplitterCloneable psc = PaymentSplitterCloneable(payable(splitter));

        uint256 balance = splitter.balance;

        uint256 totalReleased = psc.totalReleased();
        uint256 totalShares = psc.totalShares();
        uint numPayees = psc.numPayees();
        uint256[] memory balances_ = new uint256[](numPayees);
        uint256 totalReceived = balance + totalReleased;
        for (uint i = 0; i < numPayees; i++) {
            address payeeAddress = psc.payee(i);
            uint256 shares_ = psc.shares(payeeAddress);
            // adapt this logic from payment splitter
            // uint256 payment = (totalReceived * _shares[account]) / _totalShares - _released[account];

            uint256 released = psc.released(payeeAddress);
            balances_[i] = (totalReceived * shares_) / totalShares - released;
        }

        return balances_;
    }
}